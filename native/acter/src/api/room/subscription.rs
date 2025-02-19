use acter_core::referencing::ExecuteReference;
use tokio::sync::broadcast::Receiver;

use super::Room;

impl Room {
    pub fn subscribe<K: Into<ExecuteReference>>(&self, key: K) -> Receiver<()> {
        self.core.subscribe(key)
    }
}
