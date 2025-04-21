use super::manager::InvitationsManager;
use crate::Client;

impl Client {
    pub fn invitations(&self) -> InvitationsManager {
        InvitationsManager::new(self.clone())
    }
}
