use std::{cmp::Ordering, ops::Deref};

use crate::{Client, Room, RoomMessage};

#[derive(Debug, Clone)]
pub struct SimpleConvo {
    client: Client,
    inner: Room,
}

// internal API
impl SimpleConvo {
    pub(crate) fn new(client: Client, inner: Room) -> Self {
        SimpleConvo { client, inner }
    }
}

// External API

impl SimpleConvo {
    pub(crate) fn update_room(self, room: Room) -> Self {
        let SimpleConvo { client, .. } = self;
        SimpleConvo {
            client,
            inner: room,
        }
    }
}

impl Deref for SimpleConvo {
    type Target = Room;
    fn deref(&self) -> &Room {
        &self.inner
    }
}
