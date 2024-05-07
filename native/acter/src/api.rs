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
mod backup;
mod calendar_events;
mod client;
mod comments;
mod common;
mod convo;
mod device;
mod invitation;
mod message;
mod news;
mod pins;
mod profile;
mod push;
mod reactions;
mod receipt;
mod room;
mod rsvp;
mod search;
mod settings;
mod spaces;
mod stream;
mod super_invites;
mod tasks;
mod three_pid;
mod typing;
mod utils;
mod verification;

#[cfg(feature = "uniffi")]
mod uniffi_api;

#[cfg(feature = "uniffi")]
pub use uniffi_api::*;

pub use account::Account;
pub use acter_core::{
    events::{
        news::NewsContent, Colorize, ColorizeBuilder, ObjRef, ObjRefBuilder, RefDetails,
        RefDetailsBuilder, UtcDateTime,
    },
    models::{ActerModel, Tag, TextMessageContent},
};
pub use attachments::{Attachment, AttachmentDraft, AttachmentsManager};
pub use auth::{
    destroy_local_data, guest_client, login_new_client, login_with_token, register_with_token,
    set_proxy,
};
#[cfg(feature = "testing")]
pub use auth::{
    login_new_client_under_config, login_with_token_under_config, make_client_config,
    register_under_config, register_with_token_under_config, sanitize_user,
};
pub use backup::BackupManager;
pub use calendar_events::{CalendarEvent, CalendarEventDraft, CalendarEventUpdateBuilder};
pub use client::{Client, ClientStateBuilder, HistoryLoadState, SyncState};
pub use comments::{Comment, CommentDraft, CommentsManager};
pub use common::{
    duration_from_secs, new_calendar_event_ref_builder, new_colorize_builder, new_link_ref_builder,
    new_obj_ref_builder, new_task_list_ref_builder, new_task_ref_builder, new_thumb_size,
    DeviceRecord, MediaSource, MsgContent, OptionBuffer, OptionRsvpStatus, OptionString,
    ReactionRecord, ThumbnailInfo, ThumbnailSize,
};
pub use convo::{
    new_convo_settings_builder, Convo, ConvoDiff, CreateConvoSettings, CreateConvoSettingsBuilder,
};
pub use core::time::Duration as EfkDuration;
pub use device::{DeviceChangedEvent, DeviceNewEvent};
pub use invitation::Invitation;
pub use message::{EventSendState, RoomEventItem, RoomMessage, RoomVirtualItem};
pub use news::{NewsEntry, NewsEntryDraft, NewsEntryUpdateBuilder, NewsSlide, NewsSlideDraft};
pub use pins::{Pin as ActerPin, PinDraft, PinUpdateBuilder};
pub use profile::{RoomProfile, UserProfile};
pub use push::{
    NotificationItem, NotificationRoom, NotificationSender, NotificationSettings, Pusher,
};
pub use reactions::{Reaction, ReactionManager};
pub use receipt::{ReceiptEvent, ReceiptRecord, ReceiptThread};
pub use room::{
    new_join_rule_builder, JoinRuleBuilder, Member, MemberPermission, MembershipStatus, Room,
    SpaceHierarchyListResult, SpaceHierarchyRoomInfo, SpaceRelation, SpaceRelations,
};
pub use rsvp::{Rsvp, RsvpDraft, RsvpManager, RsvpStatus};
pub use search::{PublicSearchResult, PublicSearchResultItem};
pub use settings::{
    ActerAppSettings, ActerAppSettingsBuilder, ActerUserAppSettings, ActerUserAppSettingsBuilder,
    EventsSettings, NewsSettings, PinsSettings, RoomPowerLevels, SimpleSettingWithTurnOff,
    SimpleSettingWithTurnOffBuilder, TasksSettings, TasksSettingsBuilder,
};
pub use spaces::{
    new_space_settings_builder, CreateSpaceSettings, CreateSpaceSettingsBuilder,
    RelationTargetType, Space, SpaceDiff,
};
pub use stream::{MsgDraft, RoomMessageDiff, TimelineStream};
pub use super_invites::{SuperInviteToken, SuperInvites, SuperInvitesTokenUpdateBuilder};
pub use tasks::{
    Task, TaskDraft, TaskList, TaskListDraft, TaskListUpdateBuilder, TaskUpdateBuilder,
};
pub use three_pid::ThreePidManager;
pub use typing::TypingEvent;
pub use utils::parse_markdown;
pub use verification::{SessionManager, VerificationEmoji, VerificationEvent};

pub type DeviceId = ruma_common::OwnedDeviceId;
pub type EventId = ruma_common::OwnedEventId;
pub type MxcUri = ruma_common::OwnedMxcUri;
pub type RoomId = ruma_common::OwnedRoomId;
pub type UserId = ruma_common::OwnedUserId;

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
// reexport
pub use platform::{init_logging, rotate_log_file, would_log, write_log};
