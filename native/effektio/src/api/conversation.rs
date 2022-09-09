use anyhow::Context;
use futures::{pin_mut, StreamExt};
use futures_signals::{
    signal::{Mutable, SignalExt, SignalStream},
    signal_vec::{MutableSignalVec, MutableVec, SignalVecExt, ToSignalCloned},
};
use log::{error, info, warn};
use matrix_sdk::{
    event_handler::Ctx,
    room::Room as MatrixRoom,
    ruma::events::room::message::{
        MessageType, OriginalSyncRoomMessageEvent, TextMessageEventContent,
    },
    Client as MatrixClient,
};

use super::{
    client::{devide_groups_from_common, Client},
    message::sync_event_to_message,
    room::Room,
    RUNTIME,
};

#[derive(Clone)]
pub struct ConversationMessage {
    body: String,
    sender: String,
    origin_server_ts: u64,
}

impl ConversationMessage {
    pub(crate) fn new(body: String, sender: String, origin_server_ts: u64) -> Self {
        ConversationMessage {
            body,
            sender,
            origin_server_ts,
        }
    }

    pub fn body(&self) -> String {
        self.body.clone()
    }

    pub fn sender(&self) -> String {
        self.sender.clone()
    }

    pub fn origin_server_ts(&self) -> u64 {
        self.origin_server_ts
    }
}

#[derive(Clone)]
pub struct Conversation {
    inner: Room,
    latest_msg: Mutable<Option<ConversationMessage>>,
}

impl Conversation {
    pub(crate) fn new(inner: Room) -> Self {
        let room = inner.room.clone();
        let res = Conversation {
            inner,
            latest_msg: Default::default(),
        };

        let me = res.clone();
        // FIXME: hold this handler!
        RUNTIME.spawn(async move {
            let (forward, backward) = room
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
                            me.set_latest_msg(msg.body(), msg.sender(), msg.origin_server_ts());
                            break;
                        }
                    }
                    Some(Err(e)) => {
                        error!("Error fetching messages {:}", e);
                        break;
                    }
                    None => {
                        warn!("No old messages found");
                        break;
                    }
                }
            }

            pin_mut!(forward);
            // now continue to poll for incoming messages
            loop {
                match forward.next().await {
                    Some(ev) => {
                        info!("conversation timeline backward");
                        if let Some(msg) = sync_event_to_message(ev, room.clone()) {
                            me.set_latest_msg(msg.body(), msg.sender(), msg.origin_server_ts());
                            break;
                        }
                    }
                    None => {
                        warn!("Messages stream stopped");
                        break;
                    }
                }
            }
        });

        res
    }

    pub(crate) fn set_latest_msg(&self, body: String, sender: String, origin_server_ts: u64) {
        let msg = ConversationMessage::new(body, sender, origin_server_ts);
        self.latest_msg.set(Some(msg));
    }

    pub fn latest_msg(&self) -> Option<ConversationMessage> {
        self.latest_msg.lock_mut().take()
    }
}

impl std::ops::Deref for Conversation {
    type Target = Room;
    fn deref(&self) -> &Room {
        &self.inner
    }
}

#[derive(Clone)]
pub(crate) struct ConversationController {
    conversations: MutableVec<Conversation>,
}

impl ConversationController {
    pub(crate) fn new() -> Self {
        ConversationController {
            conversations: Default::default(),
        }
    }

    pub(crate) async fn setup(&self, client: &MatrixClient) {
        info!("conversation controller setup");
        let (_, convos) = devide_groups_from_common(client.clone()).await;

        self.conversations.lock_mut().replace_cloned(convos);
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
            for (idx, convo) in convos.iter().enumerate() {
                if convo.room_id() == room_id {
                    convo.set_latest_msg(
                        msg_body,
                        ev.sender.to_string(),
                        ev.origin_server_ts.as_secs().into(),
                    );
                    convos.set_cloned(idx, convo.clone());
                    convos.move_from_to(idx, 0);
                    break;
                }
            }
        }
    }
}

impl Client {
    pub fn conversations_rx(&self) -> SignalStream<ToSignalCloned<MutableSignalVec<Conversation>>> {
        self.conversations_diff_rx().to_signal_cloned().to_stream()
    }

    pub fn conversations_diff_rx(&self) -> MutableSignalVec<Conversation> {
        self.conversation_controller
            .conversations
            .signal_vec_cloned()
    }
}
