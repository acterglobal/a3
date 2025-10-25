use crate::traits::{Error, StoreError};

use super::{AccountData, ModelType, ObjectId, RedactionReason, RoomId, Timestamp, UserId};
use std::hash::Hash;

// Configure the types related as one
pub trait TypeConfig: core::fmt::Debug + PartialEq + Eq + Hash {
    type RoomId: RoomId;
    type ObjectId: ObjectId;
    type ModelType: ModelType;
    type AccountData: AccountData;
    type UserId: UserId;
    type Timestamp: Timestamp;
    type RedactionReason: RedactionReason;
    type Error: Error + StoreError;
}
