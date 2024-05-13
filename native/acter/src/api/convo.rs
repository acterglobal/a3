use acter_core::{statics::default_acter_convo_states, Error};
use anyhow::{bail, Context, Result};
use derive_builder::Builder;
use futures::stream::{Stream, StreamExt};
use matrix_sdk::{executor::JoinHandle, RoomMemberships};
use matrix_sdk_ui::{
    timeline::{PaginationOptions, RoomExt},
    Timeline,
};
use ruma::assign;
use ruma_client_api::room::{create_room, Visibility};
use ruma_common::{
    serde::Raw, MxcUri, OwnedRoomAliasId, OwnedRoomId, OwnedUserId, RoomAliasId, RoomId,
    RoomOrAliasId, ServerName, UserId,
};
use ruma_events::{
    receipt::{ReceiptThread, ReceiptType},
    room::{
        avatar::{ImageInfo, InitialRoomAvatarEvent, RoomAvatarEventContent},
        join_rules::{AllowRule, InitialRoomJoinRulesEvent, RoomJoinRulesEventContent},
    },
    space::parent::SpaceParentEventContent,
    InitialStateEvent,
};
use std::{
    ops::Deref,
    path::PathBuf,
    sync::{Arc, RwLock},
};
use tokio_retry::{strategy::FixedInterval, Retry};
use tracing::{error, info, trace, warn};

use crate::TimelineStream;

use super::{
    client::Client,
    message::RoomMessage,
    receipt::ReceiptRecord,
    room::Room,
    utils::{remap_for_diff, ApiVectorDiff},
    RUNTIME,
};

pub type ConvoDiff = ApiVectorDiff<Convo>;
type LatestMsgLock = Arc<RwLock<Option<RoomMessage>>>;

#[derive(Clone, Debug)]
pub struct Convo {
    client: Client,
    inner: Room,
    latest_message: LatestMsgLock,
    timeline: Arc<Timeline>,
    timeline_listener: Arc<JoinHandle<()>>,
}

impl PartialEq for Convo {
    fn eq(&self, other: &Self) -> bool {
        self.inner.room_id() == other.inner.room_id()
            && self.latest_message_ts() == other.latest_message_ts()
    }
}

impl Eq for Convo {}

impl PartialOrd for Convo {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for Convo {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        other.latest_message_ts().cmp(&self.latest_message_ts())
    }
}

fn latest_message_storage_key(room_id: &RoomId) -> String {
    format!("{room_id}::latest_message")
}

async fn set_latest_msg(
    client: &Client,
    room_id: &RoomId,
    lock: &LatestMsgLock,
    new_msg: RoomMessage,
) {
    let key = latest_message_storage_key(room_id);
    {
        let Ok(mut msg_lock) = lock.write() else {
            error!(
                ?room_id,
                "Locking latest message for update failed. poisoned."
            );
            return;
        };

        if let Some(prev) = msg_lock.deref() {
            if prev.event_id() == new_msg.event_id() && new_msg.event_type() == prev.event_type() {
                trace!("Nothing to update, room message stayed the same");
                return;
            }
        }
        trace!(?room_id, "Setting latest message");
        *msg_lock = Some(new_msg.clone());
    }

    client.store().set_raw(&key, &new_msg).await;
    client.executor().notify(vec![key]);
}

impl Convo {
    pub(crate) async fn new(client: Client, inner: Room) -> Self {
        let timeline = Arc::new(
            inner
                .room
                .timeline()
                .await
                .expect("Creating a timeline builder doesn't fail"),
        );
        let latest_message_content: Option<RoomMessage> = client
            .store()
            .get_raw(&latest_message_storage_key(inner.room_id()))
            .await
            .ok();

        let has_latest_msg = latest_message_content.is_some();
        let latest_message = Arc::new(RwLock::new(latest_message_content));

        let user_id = client
            .deref()
            .user_id()
            .expect("User must be logged in")
            .to_owned();
        let latest_msg_room = inner.clone();
        let latest_msg_client = client.clone();
        let last_msg_tl = timeline.clone();
        let last_msg_lock_tl = latest_message.clone();

        let listener = RUNTIME.spawn(async move {
            let (current, mut incoming) = last_msg_tl.subscribe().await;
            let mut event_found = false;
            for msg in current.into_iter().rev() {
                if msg.as_event().is_some() {
                    let full_event = RoomMessage::from((msg, user_id.clone()));
                    set_latest_msg(
                        &latest_msg_client,
                        latest_msg_room.room_id(),
                        &last_msg_lock_tl,
                        full_event,
                    )
                    .await;
                    event_found = true;
                    break;
                }
            }
            if (!event_found && !has_latest_msg) {
                // let's trigger a back pagination in hope that helps us...
                let options = PaginationOptions::until_num_items(20, 10);
                if let Err(error) = last_msg_tl.paginate_backwards(options).await {
                    error!(?error, room_id=?latest_msg_room.room_id(), "backpagination failed");
                }
            }
            while let Some(ev) = incoming.next().await {
                let Some(msg) = last_msg_tl.latest_event().await else {
                    continue;
                };
                let full_event = RoomMessage::from((msg, user_id.clone()));
                set_latest_msg(
                    &latest_msg_client,
                    latest_msg_room.room_id(),
                    &last_msg_lock_tl,
                    full_event,
                )
                .await;
            }
            warn!(room_id=?latest_msg_room.room_id(), "Timeline stopped")
        });

        Convo {
            inner,
            client,
            latest_message,
            timeline,
            timeline_listener: Arc::new(listener),
        }
    }

    pub(crate) fn update_room(self, room: Room) -> Self {
        let Convo {
            client,
            latest_message,
            timeline,
            timeline_listener,
            ..
        } = self;
        Convo {
            client,
            timeline,
            latest_message,
            timeline_listener,
            inner: room,
        }
    }

    pub fn timeline_stream(&self) -> TimelineStream {
        TimelineStream::new(self.inner.clone(), self.timeline.clone())
    }

    pub fn latest_message_ts(&self) -> u64 {
        self.latest_message
            .read()
            .map(|a| a.as_ref().map(|r| r.origin_server_ts()))
            .ok()
            .flatten()
            .flatten()
            .unwrap_or_default()
    }

    pub fn latest_message(&self) -> Option<RoomMessage> {
        self.latest_message.read().map(|i| i.clone()).ok().flatten()
    }

    pub fn get_room_id(&self) -> OwnedRoomId {
        self.room_id().to_owned()
    }

    pub fn get_room_id_str(&self) -> String {
        self.room_id().to_string()
    }

    pub fn is_dm(&self) -> bool {
        self.inner.room.direct_targets_length() > 0
    }

    pub fn is_favorite(&self) -> bool {
        self.inner.room.is_favourite()
    }

    pub async fn set_favorite(&self, is_favorite: bool) -> Result<bool> {
        let room = self.inner.room.clone();
        Ok(RUNTIME
            .spawn(async move {
                room.set_is_favourite(is_favorite, None)
                    .await
                    .map(|()| true)
            })
            .await??)
    }

    pub fn is_low_priority(&self) -> bool {
        self.inner.room.is_low_priority()
    }

    pub async fn permalink(&self) -> Result<String> {
        let room = self.inner.room.clone();
        Ok(RUNTIME
            .spawn(async move { room.matrix_permalink(false).await.map(|u| u.to_string()) })
            .await??)
    }

    pub fn dm_users(&self) -> Vec<String> {
        self.inner
            .room
            .direct_targets()
            .iter()
            .map(|f| f.to_string())
            .collect()
    }

    pub async fn user_receipts(&self) -> Result<Vec<ReceiptRecord>> {
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let mut records = vec![];
                for member in room.members(RoomMemberships::ACTIVE).await? {
                    let user_id = member.user_id();
                    if let Some((event_id, receipt)) = room
                        .load_user_receipt(ReceiptType::Read, ReceiptThread::Main, user_id)
                        .await?
                    {
                        let record = ReceiptRecord::new(
                            event_id,
                            user_id.to_owned(),
                            receipt.ts,
                            receipt.thread,
                            ReceiptType::Read,
                        );
                        records.push(record);
                    }
                    if let Some((event_id, receipt)) = room
                        .load_user_receipt(ReceiptType::ReadPrivate, ReceiptThread::Main, user_id)
                        .await?
                    {
                        let record = ReceiptRecord::new(
                            event_id,
                            user_id.to_owned(),
                            receipt.ts,
                            receipt.thread,
                            ReceiptType::ReadPrivate,
                        );
                        records.push(record);
                    }
                }
                Ok(records)
            })
            .await?
    }
}

impl Deref for Convo {
    type Target = Room;
    fn deref(&self) -> &Room {
        &self.inner
    }
}

#[derive(Builder, Default, Clone)]
pub struct CreateConvoSettings {
    #[builder(setter(into, strip_option), default)]
    name: Option<String>,

    // #[builder(default = "Visibility::Private")]
    // visibility: Visibility,
    #[builder(default = "Vec::new()")]
    invites: Vec<OwnedUserId>,

    #[builder(setter(into, strip_option), default)]
    alias: Option<String>,

    #[builder(setter(into, strip_option), default)]
    topic: Option<String>,

    #[builder(setter(strip_option), default)]
    avatar_uri: Option<String>,

    #[builder(setter(strip_option), default)]
    parent: Option<OwnedRoomId>,
}

// helper for built-in setters
impl CreateConvoSettingsBuilder {
    pub fn set_name(&mut self, value: String) {
        self.name(value);
    }

    pub fn set_alias(&mut self, value: String) {
        self.alias(value);
    }

    pub fn set_topic(&mut self, value: String) {
        self.topic(value);
    }

    pub fn add_invitee(&mut self, value: String) -> Result<()> {
        if let Ok(user_id) = UserId::parse(value) {
            if let Some(mut invites) = self.invites.clone() {
                invites.push(user_id);
                self.invites = Some(invites);
            } else {
                self.invites = Some(vec![user_id]);
            }
        }
        Ok(())
    }

    pub fn set_avatar_uri(&mut self, value: String) {
        self.avatar_uri(value);
    }

    pub fn set_parent(&mut self, value: String) {
        if let Ok(parent) = RoomId::parse(value) {
            self.parent(parent);
        }
    }
}

pub fn new_convo_settings_builder() -> CreateConvoSettingsBuilder {
    CreateConvoSettingsBuilder::default()
}

impl Client {
    pub async fn create_convo(&self, settings: Box<CreateConvoSettings>) -> Result<OwnedRoomId> {
        let client = self.core.client().clone();

        RUNTIME
            .spawn(async move {
                let mut initial_states = default_acter_convo_states();

                if let Some(avatar_uri) = settings.avatar_uri {
                    let uri = Box::<MxcUri>::from(avatar_uri.as_str());
                    let avatar_content = if uri.is_valid() {
                        // remote uri
                        assign!(RoomAvatarEventContent::new(), {
                            url: Some((*uri).to_owned()),
                        })
                    } else {
                        // local uri
                        let path = PathBuf::from(avatar_uri);
                        let guess = mime_guess::from_path(path.clone());
                        let content_type = guess.first().context("don't know mime type")?;
                        let buf = std::fs::read(path)?;
                        let response = client.media().upload(&content_type, buf).await?;

                        let info = assign!(ImageInfo::new(), {
                            blurhash: response.blurhash,
                            mimetype: Some(content_type.to_string()),
                        });
                        assign!(RoomAvatarEventContent::new(), {
                            url: Some(response.content_uri),
                            info: Some(Box::new(info)),
                        })
                    };
                    initial_states.push(InitialRoomAvatarEvent::new(avatar_content).to_raw_any());
                }

                if let Some(parent) = settings.parent {
                    let Some(Ok(homeserver)) =
                        client.homeserver().host_str().map(ServerName::parse)
                    else {
                        return Err(Error::HomeserverMissesHostname)?;
                    };
                    let parent_event = InitialStateEvent::<SpaceParentEventContent> {
                        content: assign!(SpaceParentEventContent::new(vec![homeserver]), {
                            canonical: true,
                        }),
                        state_key: parent.clone(),
                    };
                    initial_states.push(parent_event.to_raw_any());
                    // if we have a parent, by default we allow access to the subspace.
                    let join_rule =
                        InitialRoomJoinRulesEvent::new(RoomJoinRulesEventContent::restricted(
                            vec![AllowRule::room_membership(parent)],
                        ));
                    initial_states.push(join_rule.to_raw_any());
                };

                let request = assign!(create_room::v3::Request::new(), {
                    creation_content: Some(Raw::new(&create_room::v3::CreationContent::new())?),
                    initial_state: initial_states,
                    is_direct: true,
                    invite: settings.invites,
                    room_alias_name: settings.alias,
                    name: settings.name,
                    visibility: Visibility::Private,
                    topic: settings.topic,
                });
                let room = client.create_room(request).await?;
                Ok(room.room_id().to_owned())
            })
            .await?
    }

    pub async fn join_convo(
        &self,
        room_id_or_alias: String,
        server_name: Option<String>,
    ) -> Result<Convo> {
        let room = self
            .join_room(
                room_id_or_alias,
                server_name.map(|s| vec![s]).unwrap_or_default(),
            )
            .await?;
        Ok(Convo::new(self.clone(), room).await)
    }

    // ***_typed fn accepts rust-typed input, not string-based one
    async fn convo_by_alias_typed(&self, room_alias: OwnedRoomAliasId) -> Result<Convo> {
        let convo = self
            .convos
            .read()
            .await
            .iter()
            .find(|s| {
                if let Some(con_alias) = s.canonical_alias() {
                    if con_alias == room_alias {
                        return true;
                    }
                }
                for alt_alias in s.alt_aliases() {
                    if alt_alias == room_alias {
                        return true;
                    }
                }
                false
            })
            .cloned();
        match convo {
            Some(convo) => Ok(convo),
            None => {
                let room_id = self.resolve_room_alias(room_alias.clone()).await?;
                self.convo_typed(&room_id).await.context(format!(
                    "Convo with alias {room_alias} ({room_id}) not found"
                ))
            }
        }
    }

    pub async fn convo(&self, room_id_or_alias: String) -> Result<Convo> {
        self.convo_str(&room_id_or_alias).await
    }

    pub async fn convo_str(&self, room_id_or_alias: &str) -> Result<Convo> {
        let either = RoomOrAliasId::parse(room_id_or_alias)?;
        if either.is_room_id() {
            let room_id = RoomId::parse(either.as_str())?;
            self.convo_typed(&room_id)
                .await
                .context(format!("Convo {room_id} not found"))
        } else if either.is_room_alias_id() {
            let room_alias = RoomAliasId::parse(either.as_str())?;
            self.convo_by_alias_typed(room_alias).await
        } else {
            bail!("{room_id_or_alias} isn't a valid room id or alias...");
        }
    }

    /// get the convo or retry avery 250ms for retry times.
    pub async fn convo_with_retry(&self, room_id_or_alias: String, retry: u8) -> Result<Convo> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let retry_strategy = FixedInterval::from_millis(250).take(10);
                Retry::spawn(retry_strategy, || me.convo_str(&room_id_or_alias)).await
            })
            .await?
    }

    pub async fn has_convo(&self, room_id: String) -> bool {
        self.convos
            .read()
            .await
            .iter()
            .any(|s| *s.room_id() == room_id)
    }

    // ***_typed fn accepts rust-typed input, not string-based one
    pub(crate) async fn convo_typed(&self, room_id: &RoomId) -> Option<Convo> {
        self.convos
            .read()
            .await
            .iter()
            .find(|s| s.room_id() == room_id)
            .cloned()
    }

    pub fn convos_stream(&self) -> impl Stream<Item = ConvoDiff> {
        let convos = self.convos.clone();
        async_stream::stream! {
            let (current_items, stream) = {
                let locked = convos.read().await;
                (
                    ConvoDiff::current_items(locked.clone().into_iter().collect()),
                    locked.subscribe(),
                )
            };
            let mut remap = stream.into_stream().map(move |diff| remap_for_diff(diff, |x| x));
            yield current_items;

            while let Some(d) = remap.next().await {
                yield d
            }
        }
    }
}
