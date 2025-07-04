use crate::models::RedactionContent;
pub use acter_core::referencing::{
    ModelParam, ObjectListIndex, RoomParam, SectionIndex, SpecialListsIndex,
};
use acter_core::traits::TypeConfig;
use matrix_sdk::ruma::{MilliSecondsSinceUnixEpoch, OwnedEventId, OwnedRoomId, OwnedUserId};
use std::borrow::Cow;

pub type ModelType = Cow<'static, str>;
pub type AccountData = Cow<'static, str>;

#[derive(Debug, Clone, PartialEq, Eq, Hash, Ord, PartialOrd)]
pub struct MatrixCoreTypeConfig;

impl TypeConfig for MatrixCoreTypeConfig {
    type RoomId = OwnedRoomId;
    type ObjectId = OwnedEventId;
    type ModelType = ModelType;
    type AccountData = AccountData;
    type UserId = OwnedUserId;
    type Timestamp = MilliSecondsSinceUnixEpoch;
    type RedactionReason = RedactionContent;
    type Error = crate::Error;
}
