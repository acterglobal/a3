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
    pub static ref RUNTIME: Runtime = Runtime::new().expect("Can’t start Tokio runtime");
}

mod account;
mod activities;
mod attachments;
mod auth;
mod backup;
mod bookmarks;
mod calendar_events;
mod categories;
mod client;
mod comments;
mod common;
mod convo;
mod deep_linking;
mod device;
mod invitations;
mod news;
mod pins;
mod profile;
mod push;
mod reactions;
mod room;
mod rsvp;
mod search;
mod settings;
mod spaces;
mod stories;
mod super_invites;
mod tasks;
mod timeline;
mod typing;
mod utils;
mod verification;

pub mod read_receipts;
#[cfg(feature = "uniffi")]
mod uniffi_api;

#[cfg(feature = "uniffi")]
pub use uniffi_api::*;

pub use account::{Account, ExternalId, ThreePidEmailTokenResponse};
pub use acter_core::{
    events::{
        calendar::EventLocationInfo, news::NewsContent, stories::StoryContent, Category,
        CategoryBuilder, Colorize, ColorizeBuilder, Display, DisplayBuilder, ObjRefBuilder,
        UtcDateTime,
    },
    models::{
        status::{
            MembershipContent, PolicyRuleRoomContent, PolicyRuleServerContent,
            PolicyRuleUserContent, ProfileContent, RoomAvatarContent,
        },
        ActerModel, Tag, TextMessageContent,
    },
};
pub use activities::{Activities, Activity, ActivityObject};
pub use attachments::{Attachment, AttachmentDraft, AttachmentsManager};
pub use auth::{
    destroy_local_data, guest_client, login_new_client, login_with_token, register_with_token,
    request_password_change_token_via_email, request_registration_token_via_email, reset_password,
    set_proxy, PasswordChangeEmailTokenResponse, RegistrationTokenViaEmailResponse,
};
#[cfg(feature = "testing")]
pub use auth::{
    login_new_client_under_config, login_with_token_under_config, make_client_config,
    register_under_config, register_with_token_under_config, sanitize_user,
};
pub use backup::BackupManager;
pub use bookmarks::Bookmarks;
pub use calendar_events::{CalendarEvent, CalendarEventDraft, CalendarEventUpdateBuilder};
pub use categories::{Categories, CategoriesBuilder};
pub use client::{Client, ClientStateBuilder, HistoryLoadState, LocalUrlPreview, SyncState};
pub use comments::{Comment, CommentDraft, CommentsManager};
pub use common::{
    duration_from_secs, new_colorize_builder, new_display_builder, new_obj_ref_builder,
    new_thumb_size, ComposeDraft, DeviceRecord, MediaSource, OptionBuffer, OptionComposeDraft,
    OptionRsvpStatus, OptionString, ReactionRecord, ThumbnailInfo, ThumbnailSize, UrlPreview,
};
pub use convo::{
    new_convo_settings_builder, Convo, ConvoDiff, CreateConvoSettings, CreateConvoSettingsBuilder,
};
pub use core::time::Duration as EfkDuration;
pub use deep_linking::{new_link_ref_details, ObjRef, RefDetails};
pub use device::DeviceEvent;
pub use invitations::{InvitationsManager, ObjectInvitationsManager, RoomInvitation};
pub use news::{NewsEntry, NewsEntryDraft, NewsEntryUpdateBuilder, NewsSlide, NewsSlideDraft};
pub use pins::{Pin as ActerPin, PinDraft, PinUpdateBuilder};
pub use profile::UserProfile;
pub use push::{
    NotificationItem, NotificationRoom, NotificationSender, NotificationSettings, Pusher,
    SubscriptionStatus,
};
pub use reactions::{Reaction, ReactionManager};
pub use read_receipts::ReadReceiptsManager;
pub use room::{
    new_join_rule_builder, JoinRuleBuilder, Member, MemberPermission, MembershipStatus, Room,
    RoomPreview, SpaceHierarchyRoomInfo, SpaceRelation, SpaceRelations, UserRoomSettings,
};
pub use rsvp::{Rsvp, RsvpDraft, RsvpManager, RsvpStatus};
pub use search::{PublicSearchResult, PublicSearchResultItem};
pub use settings::{
    ActerAppSettings, ActerAppSettingsBuilder, ActerUserAppSettings, ActerUserAppSettingsBuilder,
    EventsSettings, NewsSettings, PinsSettings, RoomPowerLevels, SimpleOnOffSetting,
    SimpleOnOffSettingBuilder, SimpleSettingWithTurnOff, SimpleSettingWithTurnOffBuilder,
    StoriesSettings, TasksSettings,
};
pub use spaces::{
    new_app_permissions_builder, new_space_settings_builder, AppPermissionsBuilder,
    CreateSpaceSettings, CreateSpaceSettingsBuilder, RelationTargetType, Space, SpaceDiff,
};
pub use stories::{Story, StoryDraft, StorySlide, StorySlideDraft, StoryUpdateBuilder};
pub use super_invites::{
    SuperInviteInfo, SuperInviteToken, SuperInvites, SuperInvitesTokenUpdateBuilder,
};
pub use tasks::{
    Task, TaskDraft, TaskList, TaskListDraft, TaskListUpdateBuilder, TaskUpdateBuilder,
};
pub use timeline::{
    EventSendState, MsgContent, MsgDraft, TimelineEventItem, TimelineItem, TimelineItemDiff,
    TimelineStream, TimelineVirtualItem,
};
pub use typing::TypingEvent;
pub use utils::{new_vec_string_builder, VecStringBuilder};
pub use verification::{SessionManager, VerificationEmoji, VerificationEvent};

pub type DeviceId = matrix_sdk_base::ruma::OwnedDeviceId;
pub type EventId = matrix_sdk_base::ruma::OwnedEventId;
pub type MxcUri = matrix_sdk_base::ruma::OwnedMxcUri;
pub type RoomId = matrix_sdk_base::ruma::OwnedRoomId;
pub type UserId = matrix_sdk_base::ruma::OwnedUserId;

#[cfg(all(not(doctest), feature = "dart"))]
ffi_gen_macro::ffi_gen!("native/acter/api.rsh");

#[cfg(not(all(not(doctest), feature = "dart")))]
#[allow(clippy::module_inception)]
mod api {
    /// helpers for doctests, as ffigen for some reason can’t find the path
    pub struct FfiBuffer<T>(Vec<T>);
    impl<T> FfiBuffer<T> {
        pub fn new(inner: Vec<T>) -> FfiBuffer<T> {
            FfiBuffer(inner)
        }
    }
}
// reexport
pub use platform::{init_logging, rotate_log_file, would_log, write_log};
