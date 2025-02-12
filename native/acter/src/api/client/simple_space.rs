use std::ops::Deref;

use crate::{Client, Room};

#[derive(Debug, Clone)]
pub struct SimpleSpace {
    client: Client,
    inner: Room,
}

impl PartialEq for SimpleSpace {
    fn eq(&self, other: &Self) -> bool {
        self.inner.room_id() == other.inner.room_id()
    }
}

impl Eq for SimpleSpace {}

impl PartialOrd for SimpleSpace {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for SimpleSpace {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        self.room_id().cmp(other.room_id())
    }
}

// internal API
impl SimpleSpace {
    pub(crate) fn new(client: Client, inner: Room) -> Self {
        SimpleSpace { client, inner }
    }
}

// External API

impl SimpleSpace {}

impl Deref for SimpleSpace {
    type Target = Room;
    fn deref(&self) -> &Room {
        &self.inner
    }
}
