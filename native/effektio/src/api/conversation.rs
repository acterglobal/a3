use crate::RUNTIME;

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
        let outer_room_id = inner.room_id().to_owned();
        let typing_listener = client
            .typing_notification_controller
            .new_receiver()
            .filter_map(move |(room_id, user_ids)| {
                let outer_room_id = outer_room_id.clone();
                async move {
                    if room_id == outer_room_id {
                        Some(
                            user_ids
                                .into_iter()
                                .map(|u| u.to_string())
                                .collect::<Vec<_>>(),
                        )
                    } else {
                        None
                    }
                }
            });
        let typing = Mutable::new(Vec::new());
        let typing_signal = typing.clone();
        let typing_handle = RUNTIME.spawn(async move {
            pin_mut!(typing_listener);
            loop {
                typing_signal.set(typing_listener.select_next_some().await);
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
