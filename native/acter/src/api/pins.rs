use acter_matrix::{
    events::{
        pins::{self, PinBuilder},
        Display, RefDetails as CoreRefDetails, RefPreview,
    },
    models::{self, can_redact, ActerModel, AnyActerModel},
    referencing::{IndexKey, SectionIndex},
};
use anyhow::{bail, Result};
use futures::stream::StreamExt;
use matrix_sdk::room::Room;
use matrix_sdk::ruma::EventId;
use matrix_sdk_base::{
    ruma::{
        events::{room::message::TextMessageEventContent, MessageLikeEventType},
        OwnedEventId, OwnedRoomId, OwnedUserId,
    },
    RoomState,
};
use std::{
    collections::{hash_map::Entry, HashMap},
    ops::Deref,
};
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};
use tracing::warn;

use crate::MsgContent;

use super::{client::Client, deep_linking::RefDetails, spaces::Space, RUNTIME};

impl Client {
    pub async fn wait_for_pin(&self, key: String, timeout: Option<u8>) -> Result<Pin> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::Pin(content) = me.wait_for(key.clone(), timeout).await? else {
                    bail!("{key} is not a pin");
                };
                let room = me.room_by_id_typed(content.room_id())?;
                Ok(Pin {
                    client: me.clone(),
                    room,
                    content,
                })
            })
            .await?
    }

    pub async fn pins(&self) -> Result<Vec<Pin>> {
        Ok(self
            .models_of_list_with_room(IndexKey::Section(SectionIndex::Pins))
            .await?
            .map(|(inner, room)| Pin {
                client: self.clone(),
                room,
                content: inner,
            })
            .collect())
    }

    pub async fn pin(&self, pin_id: String) -> Result<Pin> {
        self.model_with_room(EventId::parse(pin_id)?)
            .await
            .map(|(inner, room)| Pin {
                client: self.clone(),
                room,
                content: inner,
            })
    }
}

impl Space {
    pub async fn pins(&self) -> Result<Vec<Pin>> {
        let room = self.room.clone();
        Ok(self
            .client
            .models_of_list_with_room_under_check(
                IndexKey::RoomSection(room.room_id().to_owned(), SectionIndex::Pins),
                move |_r| Ok(room.clone()),
            )
            .await?
            .map(|(inner, room)| Pin {
                client: self.client.clone(),
                room,
                content: inner,
            })
            .collect())
    }
}

#[derive(Clone, Debug)]
pub struct Pin {
    client: Client,
    room: Room,
    content: models::Pin,
}

impl Deref for Pin {
    type Target = models::Pin;
    fn deref(&self) -> &Self::Target {
        &self.content
    }
}

/// helpers for content
impl Pin {
    pub fn title(&self) -> String {
        self.content.title.clone()
    }

    pub fn has_formatted_text(&self) -> bool {
        matches!(
            self.content.content(),
            Some(TextMessageEventContent {
                formatted: Some(_),
                ..
            })
        )
    }

    pub async fn ref_details(&self) -> Result<RefDetails> {
        let room = self.room.clone();
        let client = self.client.deref().clone();
        let target_id = self.content.event_id().to_owned();
        let room_id = self.room.room_id().to_owned();
        let title = self.content.title.clone();

        RUNTIME
            .spawn(async move {
                let via = room.route().await?;
                let room_display_name = room.cached_display_name();
                Ok(RefDetails::new(
                    client,
                    CoreRefDetails::Pin {
                        target_id,
                        room_id: Some(room_id),
                        via,
                        preview: RefPreview::new(Some(title), room_display_name),
                        action: Default::default(),
                    },
                ))
            })
            .await?
    }

    pub fn content_formatted(&self) -> Option<String> {
        self.content
            .content
            .as_ref()
            .and_then(|t| t.formatted.as_ref().map(|f| f.body.clone()))
    }

    pub fn content(&self) -> Option<MsgContent> {
        self.content.content.as_ref().map(MsgContent::from)
    }

    pub fn display(&self) -> Option<Display> {
        self.content.display.clone()
    }

    pub fn url(&self) -> Option<String> {
        self.content.url.clone()
    }

    pub fn event_id_str(&self) -> String {
        self.content.event_id().to_string()
    }

    pub fn room_id_str(&self) -> String {
        self.content.room_id().to_string()
    }

    pub fn sender(&self) -> OwnedUserId {
        self.content.sender().to_owned()
    }
}

/// Custom functions
impl Pin {
    pub async fn refresh(&self) -> Result<Pin> {
        let key = self.content.event_id().to_owned();
        let client = self.client.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let AnyActerModel::Pin(content) = client.store().get(&key).await? else {
                    bail!("Refreshing failed. {key} not a pin")
                };
                Ok(Pin {
                    client,
                    room,
                    content,
                })
            })
            .await?
    }

    pub async fn can_redact(&self) -> Result<bool> {
        let sender = self.content.sender().to_owned();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move { Ok(can_redact(&room, &sender).await?) })
            .await?
    }

    fn is_joined(&self) -> bool {
        matches!(self.room.state(), RoomState::Joined)
    }

    pub fn update_builder(&self) -> Result<PinUpdateBuilder> {
        if !self.is_joined() {
            bail!("Can only update pins in joined rooms");
        }
        Ok(PinUpdateBuilder {
            client: self.client.clone(),
            room: self.room.clone(),
            content: self.content.updater(),
        })
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|_| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        let key = self.content.event_id().to_owned();
        self.client.subscribe(key)
    }

    pub async fn comments(&self) -> Result<crate::CommentsManager> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.content.event_id().to_owned();
        crate::CommentsManager::new(client, room, event_id).await
    }

    pub async fn attachments(&self) -> Result<crate::AttachmentsManager> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.content.event_id().to_owned();
        crate::AttachmentsManager::new(client, room, event_id).await
    }
}

#[derive(Clone)]
pub struct PinDraft {
    client: Client,
    room: Room,
    content: PinBuilder,
}

impl PinDraft {
    pub fn title(&mut self, title: String) -> &mut Self {
        self.content.title(title);
        self
    }

    pub fn content_text(&mut self, body: String) -> &mut Self {
        self.content
            .content(Some(TextMessageEventContent::plain(body)));
        self
    }

    pub fn content_markdown(&mut self, body: String) -> &mut Self {
        self.content
            .content(Some(TextMessageEventContent::markdown(body)));
        self
    }

    pub fn content_html(&mut self, body: String, html_body: String) -> &mut Self {
        self.content
            .content(Some(TextMessageEventContent::html(body, html_body)));
        self
    }

    pub fn unset_content(&mut self) -> &mut Self {
        self.content.content(None);
        self
    }

    pub fn url(&mut self, url: String) -> &mut Self {
        self.content.url(Some(url));
        self
    }

    pub fn unset_url(&mut self) -> &mut Self {
        self.content.url(None);
        self
    }

    pub fn display(&mut self, display: Box<Display>) -> &mut Self {
        self.content.display(Some(*display));
        self
    }

    pub fn unset_display(&mut self) -> &mut Self {
        self.content.display(None);
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let my_id = self.client.user_id()?;
        let content = self.content.build()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let response = room.send(content).await?;
                Ok(response.event_id)
            })
            .await?
    }
}

#[derive(Clone)]
pub struct PinUpdateBuilder {
    client: Client,
    room: Room,
    content: pins::PinUpdateBuilder,
}

impl PinUpdateBuilder {
    pub fn title(&mut self, title: String) -> &mut Self {
        self.content.title(Some(title));
        self
    }

    pub fn unset_title_update(&mut self) -> &mut Self {
        self.content.title(None);
        self
    }

    pub fn content_text(&mut self, body: String) -> &mut Self {
        self.content
            .content(Some(Some(TextMessageEventContent::plain(body))));
        self
    }

    pub fn content_markdown(&mut self, body: String) -> &mut Self {
        self.content
            .content(Some(Some(TextMessageEventContent::markdown(body))));
        self
    }

    pub fn content_html(&mut self, body: String, html_body: String) -> &mut Self {
        self.content
            .content(Some(Some(TextMessageEventContent::html(body, html_body))));
        self
    }

    pub fn unset_content(&mut self) -> &mut Self {
        self.content.content(Some(None));
        self
    }

    pub fn unset_content_update(&mut self) -> &mut Self {
        self.content
            .content(None::<Option<TextMessageEventContent>>);
        self
    }

    pub fn url(&mut self, url: String) -> &mut Self {
        self.content.url(Some(Some(url)));
        self
    }

    pub fn unset_url(&mut self) -> &mut Self {
        self.content.url(Some(None));
        self
    }

    pub fn unset_url_update(&mut self) -> &mut Self {
        self.content.url(None::<Option<String>>);
        self
    }

    pub fn display(&mut self, display: Box<Display>) -> &mut Self {
        self.content.display(Some(Some(*display)));
        self
    }

    pub fn unset_display(&mut self) -> &mut Self {
        self.content.display(Some(None));
        self
    }

    pub fn unset_display_update(&mut self) -> &mut Self {
        self.content.display(None::<Option<Display>>);
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let my_id = self.client.user_id()?;
        let content = self.content.build()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let response = room.send(content).await?;
                Ok(response.event_id)
            })
            .await?
    }
}

impl Space {
    pub fn pin_draft(&self) -> Result<PinDraft> {
        if !self.is_joined() {
            bail!("Unable to create pins for spaces we are not part on");
        }
        Ok(PinDraft {
            client: self.client.clone(),
            room: self.inner.room.clone(),
            content: Default::default(),
        })
    }

    pub fn pin_draft_with_builder(&self, content: PinBuilder) -> Result<PinDraft> {
        if !self.is_joined() {
            bail!("Unable to create pins for spaces we are not part on");
        }
        Ok(PinDraft {
            client: self.client.clone(),
            room: self.inner.room.clone(),
            content,
        })
    }
}
