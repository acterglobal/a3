use std::{
    ops::Deref,
    sync::{Arc, RwLock},
};

use crate::{Client, Room, RoomMessage};

#[derive(Debug, Clone)]
pub struct SimpleConvo {
    client: Client,
    inner: Room,
    latest_message: Arc<RwLock<Option<RoomMessage>>>,
}

impl PartialEq for SimpleConvo {
    fn eq(&self, other: &Self) -> bool {
        self.inner.room_id() == other.inner.room_id()
    }
}

impl Eq for SimpleConvo {}

impl PartialOrd for SimpleConvo {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for SimpleConvo {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        self.room_id().cmp(other.room_id())
    }
}

// internal API
impl SimpleConvo {
    pub(crate) fn new(client: Client, inner: Room) -> Self {
        SimpleConvo {
            client,
            inner,
            latest_message: Arc::new(RwLock::new(None)),
        }
    }
}

// External API

impl SimpleConvo {
    pub fn latest_message(&self) -> Option<RoomMessage> {
        self.latest_message.read().map(|i| i.clone()).ok().flatten()
    }

    pub fn latest_message_ts(&self) -> Option<u64> {
        self.latest_message
            .read()
            .map(|a| a.as_ref().map(|r| r.origin_server_ts()))
            .ok()
            .flatten()
            .flatten()
    }

    pub(crate) fn update_room(self, room: Room) -> Self {
        let SimpleConvo {
            client,
            latest_message,
            ..
        } = self;
        SimpleConvo {
            client,
            inner: room,
            latest_message,
        }
    }
}

impl Deref for SimpleConvo {
    type Target = Room;
    fn deref(&self) -> &Room {
        &self.inner
    }
}
