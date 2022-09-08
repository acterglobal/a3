use anyhow::{Context, Result};
use effektio_core::statics::{PURPOSE_FIELD, PURPOSE_FIELD_DEV, PURPOSE_TEAM_VALUE};
use futures::{
    channel::mpsc::{channel, Receiver, Sender},
    pin_mut, StreamExt,
};
use futures_signals::signal::Mutable;
use log::{info, warn};
use matrix_sdk::{
    event_handler::Ctx,
    room::Room as MatrixRoom,
    ruma::events::room::message::{
        MessageType, OriginalSyncRoomMessageEvent, SyncRoomMessageEvent, TextMessageEventContent,
    },
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
        LatestMessage {
            body,
            sender,
            origin_server_ts,
        }
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
    pub(crate) latest_msg: Mutable<Option<LatestMessage>>,
}

impl Conversation {
    pub fn get_latest_msg(&self) -> Option<LatestMessage> {
        self.latest_msg.lock_mut().take()
    }

    pub fn new(inner: Room) -> Self {
        let room = inner.room.clone();
        let s = Conversation {
            inner,
            latest_msg: Default::default(),
        };

        let me = s.clone();
        // FIXME: hold this handler!
        RUNTIME.spawn(async move {
            let (fwd, backward) = room
                .timeline()
                .await
                .context("Failed acquiring timeline streams")
                .unwrap();
            pin_mut!(backward);
            // try to find the last message in the past.
            loop {
                match backward.next().await {
                    Some(Ok(ev)) => {
                        info!("conversation timeline backward");
                        if let Some(msg) = sync_event_to_message(ev, room.clone()) {
                            let latest_msg = LatestMessage::new(
                                msg.body(),
                                msg.sender(),
                                msg.origin_server_ts(),
                            );
                            me.latest_msg.set(Some(latest_msg));
                            break;
                        }
                    }
                    Some(Err(e)) => {
                        println!("Error fetching messages {:}", e);
                        break;
                    }
                    _ => {
                        println!("No old messages found");
                        break;
                    }
                }
            }

            pin_mut!(fwd);
            // now continue to poll for incoming messages
            loop {
                match fwd.next().await {
                    Some(ev) => {
                        info!("conversation timeline backward");
                        if let Some(msg) = sync_event_to_message(ev, room.clone()) {
                            let latest_msg = LatestMessage::new(
                                msg.body(),
                                msg.sender(),
                                msg.origin_server_ts(),
                            );
                            me.latest_msg.set(Some(latest_msg));
                            break;
                        }
                    }
                    _ => {
                        println!("Messages stream stopped");
                        break;
                    }
                }
            }
        });

        s
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
    conversations: Mutable<Vec<Conversation>>,
    event_tx: Sender<Vec<Conversation>>,
    event_rx: Arc<Mutex<Option<Receiver<Vec<Conversation>>>>>,
}

impl ConversationController {
    pub(crate) fn new() -> Self {
        let (tx, rx) = channel::<Vec<Conversation>>(10); // dropping after more than 10 items queued
        ConversationController {
            conversations: Mutable::new(vec![]),
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
        }
    }

    pub fn get_event_rx(&self) -> Option<Receiver<Vec<Conversation>>> {
        self.event_rx.lock().take()
    }

    pub(crate) async fn setup(&self, client: &MatrixClient) {
        info!("conversation controller setup");
        let (_, convos) = super::client::devide_groups_from_common(client.clone()).await;

        self.conversations.set(convos);
        let mut me = self.clone();
        client
            .register_event_handler_context(me)
            .register_event_handler(
                |ev: OriginalSyncRoomMessageEvent,
                 room: MatrixRoom,
                 Ctx(me): Ctx<ConversationController>| async move {
                    info!("original sync room message event");
                    me.clone().process_room_message(ev, &room);
                },
            )
            .await
            .register_event_handler(|ev: SyncRoomMessageEvent| async move {
                info!("sync room message event");
            })
            .await;
    }

    fn process_room_message(mut self, ev: OriginalSyncRoomMessageEvent, room: &MatrixRoom) {
        let room_id = room.room_id();
        if let MatrixRoom::Joined(room) = room {
            let msg_body = match ev.content.msgtype {
                MessageType::Text(TextMessageEventContent { body, .. }) => body,
                _ => return,
            };
            let mut convos = self.conversations.lock_mut();
            for (index, convo) in convos.iter().enumerate() {
                if convo.room_id() == room_id {
                    let latest_msg = Some(LatestMessage::new(
                        msg_body,
                        ev.sender.to_string(),
                        ev.origin_server_ts.as_secs().into(),
                    ));
                    convos[index].latest_msg.set(latest_msg);
                    convos.swap(0, index);
                    let mut tx = self.event_tx.clone();
                    if let Err(e) = tx.try_send(convos.to_vec()) {
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
