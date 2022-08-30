use super::room::Room;
use super::Client;
use futures::{pin_mut, StreamExt};
use futures_signals::signal::{Mutable, MutableSignalCloned, SignalExt, SignalStream};
use tokio::task::JoinHandle;

pub struct Conversation {
    pub(crate) inner: Room,
    /// who is currently typing?
    pub typing: Mutable<Vec<String>>,
    typing_handle: JoinHandle<()>,
}

impl Conversation {
    pub fn new(inner: Room, client: &Client) -> Self {
        let room_id = inner.room_id().to_string();
        let typing_listener = client
            .typing_notification_controller
            .event_rx
            .signal_cloned()
            .filter_map(move |n| {
                if n.room_id == room_id {
                    Some(n.get_user_ids())
                } else {
                    None
                }
            })
            .to_stream();
        let typing = Mutable::new(Vec::new());
        let typing_signal = typing.clone();
        let typing_handle = tokio::spawn(async move {
            pin_mut!(typing_listener);
            loop {
                if let Some(Some(n)) = typing_listener.next().await {
                    typing_signal.set(n);
                }
            }
        });

        Conversation {
            typing,
            typing_handle,
            inner,
        }
    }

    pub fn typing_updates(&self) -> SignalStream<MutableSignalCloned<Vec<String>>> {
        self.typing.signal_cloned().to_stream()
    }
}

impl std::ops::Drop for Conversation {
    fn drop(&mut self) {
        // break the loop
        self.typing_handle.abort();
    }
}

impl std::ops::Deref for Conversation {
    type Target = Room;
    fn deref(&self) -> &Room {
        &self.inner
    }
}
