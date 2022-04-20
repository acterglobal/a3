use super::room::Room;

pub struct Group {
    pub(crate) inner: Room,
}

impl std::ops::Deref for Group {
    type Target = Room;
    fn deref(&self) -> &Room {
        &self.inner
    }
}
