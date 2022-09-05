use anyhow::{Context, Result};
use effektio_core::statics::{PURPOSE_FIELD, PURPOSE_FIELD_DEV, PURPOSE_TEAM_VALUE};
use futures::{
    pin_mut,
    channel::mpsc::{channel, Receiver, Sender},
    StreamExt,
};
use log::{info, warn};
use matrix_sdk::{
    event_handler::Ctx,
    room::Room as MatrixRoom,
    ruma::events::room::message::{MessageType, OriginalSyncRoomMessageEvent, TextMessageEventContent},
    Client as MatrixClient,
};
use parking_lot::Mutex;
use std::sync::Arc;

use super::{client::Client, message::sync_event_to_message, room::Room, RUNTIME};

#[derive(Clone)]
pub struct LatestMessage {
    body: String,
    sender: String,
    origin_server_ts: u64,
}

impl LatestMessage {
    pub(crate) fn new(body: String, sender: String, origin_server_ts: u64) -> Self {
        LatestMessage { body, sender, origin_server_ts }
    }

    pub fn get_body(&self) -> String {
        self.body.clone()
    }

    pub fn get_sender(&self) -> String {
        self.sender.clone()
    }

    pub fn get_origin_server_ts(&self) -> u64 {
        self.origin_server_ts
    }
}

#[derive(Clone)]
pub struct Conversation {
    pub(crate) inner: Room,
    pub(crate) latest_msg: Option<LatestMessage>,
}

impl Conversation {
    pub fn get_latest_msg(&self) -> Option<LatestMessage> {
        self.latest_msg.clone()
    }

    pub(crate) async fn init(&self) -> Result<()> {
        let room = self.room.clone();
        let mut latest_msg = self.latest_msg.clone();
        RUNTIME
            .spawn(async move {
                let stream = room
                    .timeline_backward()
                    .await
                    .context("Failed acquiring timeline streams")?;
                pin_mut!(stream);
                loop {
                    match stream.next().await {
                        None => break,
                        Some(Ok(ev)) => {
                            if let Some(msg) = sync_event_to_message(ev, room.clone()) {
                                latest_msg = Some(LatestMessage::new(msg.body(), msg.sender(), msg.origin_server_ts()));
                                return Ok(());
                            }
                        }
                        _ => {
                            // we ignore errors
                        }
                    }
                }
                Ok(())
            })
            .await?
    }
}

impl std::ops::Deref for Conversation {
    type Target = Room;
    fn deref(&self) -> &Room {
        &self.inner
    }
}

#[derive(Clone)]
pub struct ConversationController {
    conversations: Vec<Conversation>,
    event_tx: Sender<Vec<Conversation>>,
    event_rx: Arc<Mutex<Option<Receiver<Vec<Conversation>>>>>,
}

impl ConversationController {
    pub(crate) fn new() -> Self {
        let (tx, rx) = channel::<Vec<Conversation>>(10); // dropping after more than 10 items queued
        ConversationController {
            conversations: vec![],
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
        }
    }

    pub fn get_event_rx(&self) -> Option<Receiver<Vec<Conversation>>> {
        self.event_rx.lock().take()
    }

    async fn devide_groups_from_common(client: MatrixClient) -> Vec<Conversation> {
        let (convos, _) = futures::stream::iter(client.clone().rooms().into_iter())
            .fold(
                (Vec::new(), client),
                async move |(mut conversations, client), room| {
                    let is_effektio_group = {
                        #[allow(clippy::match_like_matches_macro)]
                        if let Ok(Some(_)) = room
                            .get_state_event(PURPOSE_FIELD.into(), PURPOSE_TEAM_VALUE)
                            .await
                        {
                            true
                        } else if let Ok(Some(_)) = room
                            .get_state_event(PURPOSE_FIELD_DEV.into(), PURPOSE_TEAM_VALUE)
                            .await
                        {
                            true
                        } else {
                            false
                        }
                    };

                    if !is_effektio_group {
                        let item = Conversation {
                            inner: Room {
                                room,
                                client: client.clone(),
                            },
                            latest_msg: None,
                        };
                        item.init().await;
                        conversations.push(item);
                    }

                    (conversations, client)
                },
            )
            .await;
        return convos;
    }

    pub(crate) fn setup(mut self, client: &MatrixClient) {
        let mut me = self.clone();
        let client = client.clone();
        RUNTIME.spawn(async move {
            let mut me = me.clone();
            let conversations = ConversationController::devide_groups_from_common(client.clone()).await;
            me.conversations = conversations;
            info!("conversation controller setup");
            client
                .register_event_handler_context(me)
                .register_event_handler(|ev: OriginalSyncRoomMessageEvent, room: MatrixRoom, Ctx(me): Ctx<ConversationController>| async move {
                    info!("original sync room message event");
                    me.clone().process_room_message(ev, &room);
                })
                .await;
        });
    }

    fn process_room_message(mut self, ev: OriginalSyncRoomMessageEvent, room: &MatrixRoom) {
        let room_id = room.room_id();
        if let MatrixRoom::Joined(room) = room {
            let msg_body = match ev.content.msgtype {
                MessageType::Text(TextMessageEventContent { body, .. }) => body,
                _ => return,
            };
            for (index, conv) in self.conversations.iter().enumerate() {
                if conv.room_id() == room_id {
                    let latest_msg = Some(LatestMessage::new(msg_body, ev.sender.to_string(), ev.origin_server_ts.as_secs().into()));
                    self.conversations[index].latest_msg = latest_msg;
                    self.conversations.swap(0, index);
                    let mut tx = self.event_tx.clone();
                    if let Err(e) = tx.try_send(self.conversations.clone()) {
                        log::warn!("Dropping ephemeral event for {}: {}", room_id, e);
                    }
                    break;
                }
            }
        }
    }
}

impl Client {
    pub fn get_conversations_rx(&self) -> Option<Receiver<Vec<Conversation>>> {
        self.conversation_controller.event_rx.lock().take()
    }
}
