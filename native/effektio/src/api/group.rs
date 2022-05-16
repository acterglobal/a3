use super::room::Room;

pub struct Group {
    pub(crate) inner: Room,
}

impl Group {
    pub async fn sync_up(&self) -> anyhow::Result<()> {
        // FIXME: do something useful here

        todo! {}
    }
}

impl std::ops::Deref for Group {
    type Target = Room;
    fn deref(&self) -> &Room {
        &self.inner
    }
}
