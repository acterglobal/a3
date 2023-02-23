use anyhow::Result;
use futures::Stream;
pub use futures_signals::signal_vec::VecDiff;
use lazy_static::lazy_static;
use tokio::runtime;

use crate::platform;

lazy_static! {
    pub static ref RUNTIME: runtime::Runtime =
        runtime::Runtime::new().expect("Can't start Tokio runtime");
}

mod account;
mod auth;
mod client;
mod comments;
mod common;
mod conversation;
mod device;
mod group;
mod invitation;
mod message;
mod news;
mod profile;
mod receipt;
mod room;
mod stream;
mod tasks;
mod typing;
mod verification;

pub use account::Account;
pub use auth::{
    guest_client, login_new_client, login_with_token, register_with_registration_token,
};
pub use client::{Client, ClientStateBuilder, HistoryLoadState, SyncState};
pub use comments::{Comment, CommentDraft, CommentsManager};
pub use common::duration_from_secs;
pub use conversation::{Conversation, CreateConversationSettingsBuilder};
pub use core::time::Duration as EfkDuration;
pub use device::{DeviceChangedEvent, DeviceLeftEvent, DeviceRecord};
pub use effektio_core::{
    events::UtcDateTime,
    models::{Color as EfkColor, Faq, News, Tag},
};
pub use group::{new_group_settings, CreateGroupSettings, CreateGroupSettingsBuilder, Group};
pub use invitation::Invitation;
pub use message::{
    FileDesc, ImageDesc, ReactionDesc, RoomEventItem, RoomMessage, RoomVirtualItem, TextDesc,
    VideoDesc,
};
pub use profile::{RoomProfile, UserProfile};
pub use receipt::{ReceiptEvent, ReceiptRecord};
pub use room::{Member, Room};
pub use stream::{TimelineDiff, TimelineStream};
pub use tasks::{
    Task, TaskDraft, TaskList, TaskListDraft, TaskListUpdateBuilder, TaskUpdateBuilder,
};
pub use typing::TypingEvent;
pub use verification::{VerificationEmoji, VerificationEvent};

#[cfg(feature = "with-mocks")]
pub use effektio_core::mocks::*;

pub use effektio_core::ruma::events::room::MediaSource;

pub type DeviceId = effektio_core::ruma::OwnedDeviceId;
pub type EventId = effektio_core::ruma::OwnedEventId;
pub type RoomId = effektio_core::ruma::OwnedRoomId;
pub type UserId = effektio_core::ruma::OwnedUserId;

#[cfg(all(not(doctest), feature = "dart"))]
ffi_gen_macro::ffi_gen!("native/effektio/api.rsh");

#[cfg(not(all(not(doctest), feature = "dart")))]
#[allow(clippy::module_inception)]
mod api {
    /// helpers for doctests, as ffigen for some reason can't find the path
    pub struct FfiBuffer<T>(Vec<T>);
    impl<T> FfiBuffer<T> {
        pub fn new(inner: Vec<T>) -> FfiBuffer<T> {
            FfiBuffer(inner)
        }
    }
}

fn init_logging(app_name: String, log_dir: String, filter: Option<String>) -> Result<()> {
    platform::init_logging(app_name, log_dir, filter)
}

fn report_bug(text: String, label: String) -> Result<bool> {
    platform::report_bug(text, label)
}
