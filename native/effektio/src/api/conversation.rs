use super::room::Room;

pub struct Conversation {
    pub(crate) inner: Room,
}

impl std::ops::Deref for Conversation {
    type Target = Room;
    fn deref(&self) -> &Room {
        &self.inner
    }
}
