use acter_core::{statics::default_acter_convo_states, Error};
use anyhow::{bail, Context, Result};
use derive_builder::Builder;
use futures::stream::{Stream, StreamExt};
use matrix_sdk::{
    deserialized_responses::SyncTimelineEvent,
    event_handler::{Ctx, EventHandlerHandle},
    room::{MessagesOptions, Room as SdkRoom},
    ruma::{
        api::client::room::{
            create_room::v3::{CreationContent, Request as CreateRoomRequest},
            Visibility,
        },
        assign,
        events::{
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
        },
        serde::Raw,
        MxcUri, OwnedRoomId, OwnedUserId, RoomId, UserId,
    },
    Client as SdkClient, RoomMemberships,
};
use matrix_sdk_ui::{
    timeline::{EventTimelineItem, RoomExt},
    Timeline,
};
use std::{ops::Deref, path::PathBuf, sync::Arc};
use tokio::sync::RwLock;
use tracing::{error, info};

use crate::TimelineStream;

use super::{
    client::Client,
    message::{sync_event_to_message, RoomMessage},
    receipt::ReceiptRecord,
    room::Room,
    utils::{remap_for_diff, ApiVectorDiff},
    RUNTIME,
};

pub type ConvoDiff = ApiVectorDiff<Convo>;

#[derive(Clone, Debug)]
pub struct Convo {
    client: Client,
    inner: Room,
    timeline: Arc<Timeline>,
}

impl Convo {
    pub(crate) async fn new(client: Client, inner: Room) -> Self {
        let timeline = inner.room.timeline().await;
        Convo {
            inner,
            client,
            timeline: Arc::new(timeline),
        }
    }

    pub(crate) fn update_room(self, room: Room) -> Self {
        let Convo {
            client, timeline, ..
        } = self;
        Convo {
            client,
            timeline,
            inner: room,
        }
    }

    pub async fn timeline_stream(&self) -> Result<TimelineStream> {
        Ok(TimelineStream::new(
            self.inner.room.clone(),
            self.timeline.clone(),
        ))
    }

    pub async fn latest_message_ts(&self) -> u64 {
        self.timeline
            .latest_event()
            .await
            .map(|event| event.timestamp().as_secs().into())
            .unwrap_or_default()
    }

    pub async fn latest_message(&self) -> Result<RoomMessage> {
        self.timeline
            .latest_event()
            .await
            .map(|event| RoomMessage::from_timeline_event_item(&event, self.inner.room.clone()))
            .context("No latest message found")
    }

    pub fn get_room_id(&self) -> OwnedRoomId {
        self.room_id().to_owned()
    }

    pub fn get_room_id_str(&self) -> String {
        self.room_id().to_string()
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
                    let Some(Ok(homeserver)) = client.homeserver().await.host_str().map(|h|h.try_into()) else {
                      return Err(Error::HomeserverMissesHostname)?;
                    };
                    let parent_event = InitialStateEvent::<SpaceParentEventContent> {
                        content: assign!(SpaceParentEventContent::new(true), {
                            via: Some(vec![homeserver]),
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

                let request = assign!(CreateRoomRequest::new(), {
                    creation_content: Some(Raw::new(&CreationContent::new())?),
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

    pub async fn convo(&self, room_id_or_alias: String) -> Result<Convo> {
        let room_id = self.resolve_room_id_or_alias(room_id_or_alias).await?;
        self.convo_typed(&room_id).await.context("Chat not found")
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
            let mut remap = stream.map(move |diff| remap_for_diff(diff, |x| x));
            yield current_items;

            while let Some(d) = remap.next().await {
                yield d
            }
        }
    }
}
