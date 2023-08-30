use anyhow::Result;
use futures::Stream;
use lazy_static::lazy_static;
use tokio::runtime::Runtime;

use crate::platform;

#[no_mangle]
pub extern "C" fn __hello_world() {
    // DO NOT REMOVE.
    // empty external linking helper, noop but needed for
    // iOS to properly link the headers and lib into
    // the binary.
    // DO NOT REMOVE.
}

lazy_static! {
    pub static ref RUNTIME: Runtime = Runtime::new().expect("Can't start Tokio runtime");
}

mod account;
mod attachments;
mod auth;
mod calendar_events;
mod client;
mod comments;
mod common;
mod convo;
mod device;
mod invitation;
mod message;
mod news;
mod notifications;
mod pins;
mod profile;
mod push;
mod receipt;
mod room;
mod rsvp;
mod search;
mod settings;
mod spaces;
mod stream;
mod tasks;
mod typing;
mod utils;
mod verification;

pub use account::Account;
pub use acter_core::{
    events::{news::NewsContent, Colorize, ObjRef, RefDetails, UtcDateTime},
    models::{ActerModel, Color as EfkColor, Tag, TextMessageContent},
};
pub use attachments::{Attachment, AttachmentDraft, AttachmentsManager};
pub use auth::{
    destroy_local_data, guest_client, login_new_client, login_new_client_under_config,
    login_with_token, login_with_token_under_config, make_client_config, register_under_config,
    register_with_token, register_with_token_under_config, sanitize_user,
};
pub use calendar_events::{CalendarEvent, CalendarEventDraft, CalendarEventUpdateBuilder};
pub use client::{Client, ClientStateBuilder, HistoryLoadState, SyncState};
pub use comments::{Comment, CommentDraft, CommentsManager};
pub use common::{
    duration_from_secs, AudioDesc, DeviceRecord, FileDesc, ImageDesc, MediaSource, OptionBuffer,
    OptionString, ReactionRecord, TextDesc, ThumbnailInfo, VideoDesc,
};
pub use convo::{
    new_convo_settings_builder, Convo, CreateConvoSettings, CreateConvoSettingsBuilder,
};
pub use core::time::Duration as EfkDuration;
pub use device::{DeviceChangedEvent, DeviceLeftEvent};
pub use invitation::Invitation;
pub use message::{RoomEventItem, RoomMessage, RoomVirtualItem};
pub use news::{NewsEntry, NewsEntryDraft, NewsEntryUpdateBuilder, NewsSlide};
pub use notifications::{Notification, NotificationListResult};
pub use pins::{Pin as ActerPin, PinDraft, PinUpdateBuilder};
pub use profile::{RoomProfile, UserProfile};
pub use receipt::{ReceiptEvent, ReceiptRecord};
pub use room::{Member, MemberPermission, MembershipStatus, Room};
pub use rsvp::{Rsvp, RsvpDraft, RsvpManager};
pub use search::{PublicSearchResult, PublicSearchResultItem};
pub use settings::{
    ActerAppSettings, ActerAppSettingsBuilder, EventsSettings, NewsSettings, PinsSettings,
    RoomPowerLevels, SimpleSettingWithTurnOff, SimpleSettingWithTurnOffBuilder,
};
pub use spaces::{
    new_space_settings_builder, CreateSpaceSettings, CreateSpaceSettingsBuilder,
    RelationTargetType, Space, SpaceHierarchyListResult, SpaceHierarchyRoomInfo, SpaceRelation,
    SpaceRelations,
};
pub use stream::{TimelineDiff, TimelineStream};
pub use tasks::{
    Task, TaskDraft, TaskList, TaskListDraft, TaskListUpdateBuilder, TaskUpdateBuilder,
};
pub use typing::TypingEvent;
pub use utils::parse_markdown;
pub use verification::{SessionManager, VerificationEmoji, VerificationEvent};

pub type DeviceId = matrix_sdk::ruma::OwnedDeviceId;
pub type EventId = matrix_sdk::ruma::OwnedEventId;
pub type MxcUri = matrix_sdk::ruma::OwnedMxcUri;
pub type RoomId = matrix_sdk::ruma::OwnedRoomId;
pub type UserId = matrix_sdk::ruma::OwnedUserId;

#[cfg(all(not(doctest), feature = "dart"))]
ffi_gen_macro::ffi_gen!("native/acter/api.rsh");

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

fn init_logging(log_dir: String, filter: String) -> Result<()> {
    platform::init_logging(log_dir, filter)
}

fn rotate_log_file() -> Result<String> {
    platform::rotate_log_file()
}

fn write_log(text: String, level: String) -> Result<()> {
    platform::write_log(text, level)
}
