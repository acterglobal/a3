use acter_core::{statics::default_acter_convo_states, Error};
use anyhow::{bail, Context, Result};
use derive_builder::Builder;
use futures::stream::{Stream, StreamExt};

use matrix_sdk::{
    deserialized_responses::SyncTimelineEvent,
    event_handler::{Ctx, EventHandlerHandle},
    executor::JoinHandle,
    room::MessagesOptions,
    ruma::{
        api::client::room::{create_room, Visibility},
        assign,
    },
    Client as SdkClient, RoomMemberships,
};
use matrix_sdk_ui::{
    timeline::{EventTimelineItem, PaginationOptions, RoomExt, TimelineItem},
    Timeline,
};
use ruma_common::{
    serde::Raw, MxcUri, OwnedRoomAliasId, OwnedRoomId, OwnedRoomOrAliasId, OwnedUserId, RoomId,
    UserId,
};
use ruma_events::{
    receipt::{ReceiptThread, ReceiptType},
    room::{
        avatar::{ImageInfo, InitialRoomAvatarEvent, RoomAvatarEventContent},
        encrypted::OriginalSyncRoomEncryptedEvent,
        join_rules::{AllowRule, InitialRoomJoinRulesEvent, RoomJoinRulesEventContent},
        member::{MembershipState, OriginalSyncRoomMemberEvent},
        message::OriginalSyncRoomMessageEvent,
        redaction::SyncRoomRedactionEvent,
    },
    space::parent::SpaceParentEventContent,
    AnySyncTimelineEvent, InitialStateEvent,
};
use std::{
    ops::Deref,
    path::PathBuf,
    sync::{Arc, RwLock as StdRwLock},
};
use tokio_retry::{strategy::FixedInterval, Retry};
use tracing::{error, info, trace, warn};

use crate::{SpaceRelations, TimelineStream};

use super::{
    client::Client,
    message::RoomMessage,
    receipt::ReceiptRecord,
    room::{self, Room},
    utils::{remap_for_diff, ApiVectorDiff},
    RUNTIME,
};

pub type ConvoDiff = ApiVectorDiff<Convo>;
type LatestMsgLock = Arc<StdRwLock<Option<RoomMessage>>>;

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
        other
            .latest_message_ts()
            .partial_cmp(&self.latest_message_ts())
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
            error!(?room_id, "Locking latest message for update failed. poisoned.");
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
        let timeline = Arc::new(inner.room.timeline().await);
        let latest_message_content: Option<RoomMessage> = client
            .store()
            .get_raw(&latest_message_storage_key(inner.room_id()))
            .await
            .ok();

        let has_latest_msg = latest_message_content.is_some();
        let latest_message: LatestMsgLock = Arc::new(StdRwLock::new(latest_message_content));

        let latest_msg_room = inner.clone();
        let latest_msg_client = client.clone();
        let last_msg_tl = timeline.clone();
        let last_msg_lock_tl = latest_message.clone();

        let listener = RUNTIME.spawn(async move {
            let (current, mut incoming) = last_msg_tl.subscribe().await;
            let mut event_found = false;
            for msg in current.into_iter().rev() {
                if msg.as_event().is_some() {
                    let full_event = RoomMessage::from((msg, latest_msg_room.room.clone()));
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
                // let's trigger a backpagination in hope that helps us...
                let options = PaginationOptions::until_num_items(20, 10);
                if let Err(error) = last_msg_tl.paginate_backwards(options).await {
                    error!(?error, room_id=?latest_msg_room.room_id(), "backpagination failed");
                }
            }
            while let Some(ev) = incoming.next().await {
                let Some(msg) = last_msg_tl.latest_event().await else { continue };
                let full_event = RoomMessage::from((msg, latest_msg_room.room.clone()));
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

    pub async fn timeline_stream(&self) -> Result<TimelineStream> {
        Ok(TimelineStream::new(
            self.inner.room.clone(),
            self.timeline.clone(),
        ))
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
        !self.inner.room.direct_targets().is_empty()
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
                        .user_receipt(ReceiptType::Read, ReceiptThread::Main, user_id)
                        .await?
                    {
                        let record = ReceiptRecord::new(event_id, user_id.to_owned(), receipt.ts);
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
                        let content_type = guess.first().expect("MIME type should be given");
                        let buf = std::fs::read(path).expect("File should be read");
                        let upload_resp = client.media().upload(&content_type, buf).await?;

                        let info = assign!(ImageInfo::new(), {
                            blurhash: upload_resp.blurhash,
                            mimetype: Some(content_type.to_string()),
                        });
                        assign!(RoomAvatarEventContent::new(), {
                            url: Some(upload_resp.content_uri),
                            info: Some(Box::new(info)),
                        })
                    };
                    initial_states.push(InitialRoomAvatarEvent::new(avatar_content).to_raw_any());
                }

                if let Some(parent) = settings.parent {
                    let Some(Ok(homeserver)) = client.homeserver().host_str().map(|h|h.try_into()) else {
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
                        InitialRoomJoinRulesEvent::new(RoomJoinRulesEventContent::restricted(vec![
                            AllowRule::room_membership(parent),
                        ]));
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
    pub async fn convo_by_alias_typed(&self, room_alias: OwnedRoomAliasId) -> Result<Convo> {
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
            .map(Clone::clone);
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
        self.convo_str(room_id_or_alias.as_str()).await
    }

    pub async fn convo_str(&self, room_id_or_alias: &str) -> Result<Convo> {
        let either = OwnedRoomOrAliasId::try_from(room_id_or_alias)?;
        if either.is_room_id() {
            let room_id = OwnedRoomId::try_from(either.as_str())?;
            self.convo_typed(&room_id)
                .await
                .context(format!("Convo {room_id} not found"))
        } else if either.is_room_alias_id() {
            let room_alias = OwnedRoomAliasId::try_from(either.as_str())?;
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
                Retry::spawn(retry_strategy, || me.convo_str(room_id_or_alias.as_str())).await
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

    pub async fn convo_typed(&self, room_id: &OwnedRoomId) -> Option<Convo> {
        self.convos
            .read()
            .await
            .iter()
            .find(|s| s.room_id() == room_id)
            .map(Clone::clone)
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
