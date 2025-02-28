use acter_core::{
    referencing::{ExecuteReference, RoomParam},
    statics::default_acter_convo_states,
    Error,
};
use anyhow::{bail, Context, Result};
use derive_builder::Builder;
use futures::stream::{Stream, StreamExt};
use matrix_sdk_base::{
    executor::JoinHandle,
    ruma::{
        api::client::room::{create_room, Visibility},
        assign,
        events::{
            room::{
                avatar::{ImageInfo, InitialRoomAvatarEvent, RoomAvatarEventContent},
                join_rules::{AllowRule, InitialRoomJoinRulesEvent, RoomJoinRulesEventContent},
            },
            space::parent::SpaceParentEventContent,
            InitialStateEvent,
        },
        serde::Raw,
        MxcUri, OwnedEventId, OwnedRoomAliasId, OwnedRoomId, OwnedUserId, RoomAliasId, RoomId,
        RoomOrAliasId, ServerName, UserId,
    },
    ComposerDraft, ComposerDraftType,
};
use matrix_sdk_ui::{timeline::RoomExt, Timeline};
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
    common::OptionRoomMessage,
    message::RoomMessage,
    room::Room,
    utils::{remap_for_diff, ApiVectorDiff},
    ComposeDraft, OptionComposeDraft, RUNTIME,
};

pub type ConvoDiff = ApiVectorDiff<Convo>;
type LatestMsgLock = Arc<RwLock<Option<RoomMessage>>>;

#[derive(Clone, Debug)]
pub struct Convo {
    client: Client,
    inner: Room,
}

fn latest_message_storage_key(room_id: &RoomId) -> ExecuteReference {
    ExecuteReference::RoomParam(room_id.to_owned(), RoomParam::LatestMessage)
}

impl Convo {
    pub(crate) fn new(client: Client, inner: Room) -> Self {
        Convo { client, inner }
    }

    pub(crate) fn update_room(self, room: Room) -> Self {
        let Convo { client, .. } = self;
        Convo {
            client,
            inner: room,
        }
    }

    pub async fn timeline_stream(&self) -> Result<TimelineStream> {
        let room = self.inner.clone();
        let sync_controller = self.client.sync_controller.clone();
        RUNTIME
            .spawn(async move {
                let timelines = sync_controller.timelines.read().await;
                let timeline = timelines
                    .get(room.room.room_id())
                    .context("timeline not started yet")?;
                Ok(TimelineStream::new(room, Arc::new(timeline.clone())))
            })
            .await?
    }

    pub async fn items(&self) -> Result<Vec<RoomMessage>> {
        let sync_controller = self.client.sync_controller.clone();
        let room_id = self.inner.room.room_id().to_owned();
        let my_id = self.client.user_id()?;
        RUNTIME
            .spawn(async move {
                let timelines = sync_controller.timelines.read().await;
                let timeline = timelines
                    .get(&room_id)
                    .context("timeline not started yet")?;
                let tl_items = timeline
                    .inner
                    .items()
                    .await
                    .into_iter()
                    .map(|x| RoomMessage::from((x, my_id.clone())))
                    .collect();
                Ok(tl_items)
            })
            .await?
    }

    pub fn num_unread_notification_count(&self) -> u64 {
        self.inner
            .room
            .unread_notification_counts()
            .notification_count
    }

    pub fn num_unread_messages(&self) -> u64 {
        self.inner.room.num_unread_messages()
    }

    pub fn num_unread_mentions(&self) -> u64 {
        self.inner.room.unread_notification_counts().highlight_count
    }

    pub async fn latest_message_ts(&self) -> Result<u64> {
        let client = self.client.clone();
        let room_id = self.inner.room.room_id().to_owned();
        RUNTIME
            .spawn(async move {
                let room_infos = client.sync_controller.room_infos.read().await;
                let info = room_infos
                    .get(&room_id)
                    .context("room info not inited yet")?;
                let ts = info.latest_msg().and_then(|x| x.origin_server_ts());
                Ok(ts.unwrap_or_default())
            })
            .await?
    }

    pub async fn latest_message(&self) -> Result<OptionRoomMessage> {
        let client = self.client.clone();
        let room_id = self.inner.room.room_id().to_owned();
        RUNTIME
            .spawn(async move {
                let room_infos = client.sync_controller.room_infos.read().await;
                let info = room_infos
                    .get(&room_id)
                    .context("room info not inited yet")?;
                Ok(OptionRoomMessage::new(info.latest_msg()))
            })
            .await?
    }

    pub fn get_room_id(&self) -> OwnedRoomId {
        self.inner.room.room_id().to_owned()
    }

    pub fn get_room_id_str(&self) -> String {
        self.inner.room.room_id().to_string()
    }

    pub fn is_dm(&self) -> bool {
        self.inner.room.direct_targets_length() > 0
    }

    pub fn is_bookmarked(&self) -> bool {
        self.inner.room.is_favourite()
    }

    pub async fn set_bookmarked(&self, is_bookmarked: bool) -> Result<bool> {
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                inner.room.set_is_favourite(is_bookmarked, None).await?;
                Ok(true)
            })
            .await?
    }

    pub fn is_low_priority(&self) -> bool {
        self.inner.room.is_low_priority()
    }

    pub async fn permalink(&self) -> Result<String> {
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                let uri = inner.room.matrix_permalink(false).await?;
                Ok(uri.to_string())
            })
            .await?
    }

    pub fn dm_users(&self) -> Vec<String> {
        self.inner
            .room
            .direct_targets()
            .iter()
            .map(|f| f.to_string())
            .collect()
    }

    pub async fn msg_draft(&self) -> Result<OptionComposeDraft> {
        if !self.inner.is_joined() {
            bail!("Unable to fetch composer draft of a room we are not in");
        }
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                let draft = inner.room.load_composer_draft().await?.map(|x| {
                    let (msg_type, event_id) = match x.draft_type {
                        ComposerDraftType::NewMessage => ("new".to_string(), None),
                        ComposerDraftType::Edit { event_id } => {
                            ("edit".to_string(), Some(event_id))
                        }
                        ComposerDraftType::Reply { event_id } => {
                            ("reply".to_string(), Some(event_id))
                        }
                    };
                    ComposeDraft::new(x.plain_text, x.html_text, msg_type, event_id)
                });
                Ok(OptionComposeDraft::new(draft))
            })
            .await?
    }

    pub async fn save_msg_draft(
        &self,
        text: String,
        html: Option<String>,
        draft_type: String,
        event_id: Option<String>,
    ) -> Result<bool> {
        if !self.is_joined() {
            bail!("Unable to save composer draft of a room we are not in");
        }
        let inner = self.inner.clone();

        let draft_type = match (draft_type.as_str(), event_id) {
            ("new", None) => ComposerDraftType::NewMessage,
            ("edit", Some(id)) => ComposerDraftType::Edit {
                event_id: OwnedEventId::try_from(id)?,
            },
            ("reply", Some(id)) => ComposerDraftType::Reply {
                event_id: OwnedEventId::try_from(id)?,
            },
            ("reply", None) | ("edit", None) => bail!("Invalid event id"),
            (draft_type, _) => bail!("Invalid draft type {draft_type}"),
        };

        let msg_draft = ComposerDraft {
            plain_text: text,
            html_text: html,
            draft_type,
        };

        RUNTIME
            .spawn(async move {
                inner.room.save_composer_draft(msg_draft).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn clear_msg_draft(&self) -> Result<bool> {
        if !self.inner.is_joined() {
            bail!("Unable to remove composer draft of a room we are not in");
        }
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                inner.room.clear_composer_draft().await?;
                Ok(true)
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
    //
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
                        let content_type = guess.first().context("don’t know mime type")?;
                        let buf = std::fs::read(path)?;
                        let response = client.media().upload(&content_type, buf, None).await?;

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
            bail!("{room_id_or_alias} isn’t a valid room id or alias...");
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
        let should_stop = self.should_stop_convos.clone();
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

            {
                let mut should_stop = should_stop.write().await;
                *should_stop = false;
            }

            while let Some(d) = remap.next().await {
                let should_stop = should_stop.read().await;
                if *should_stop {
                    break;
                }
                yield d
            }
        }
    }

    pub async fn cancel_convos_stream(&self) -> Result<bool> {
        let should_stop = self.should_stop_convos.clone();
        RUNTIME
            .spawn(async move {
                let mut should_stop = should_stop.write().await;
                *should_stop = true;
                Ok(true)
            })
            .await?
    }
}
