use acter_core::referencing::{ExecuteReference as CoreExecuteReference, IndexKey as CoreIndexKey, TypeConfig};
pub use acter_core::referencing::{
    ModelParam, ObjectListIndex, RoomParam, SectionIndex, SpecialListsIndex,
};
use matrix_sdk::ruma::{OwnedEventId, RoomId, EventId, OwnedRoomId};
use std::{borrow::Cow};


pub type ModelType = Cow<'static, str>;
pub type AccountData = Cow<'static, str>;

#[derive(Debug, Clone, PartialEq, Eq, Hash, Ord, PartialOrd)]
pub struct MatrixCoreTypeConfig;

impl TypeConfig for MatrixCoreTypeConfig {
    type RoomId = OwnedRoomId;
    type ObjectId = OwnedEventId;
    type ModelType = ModelType;
    type AccountData = AccountData;
}

pub type ExecuteReference = CoreExecuteReference<MatrixCoreTypeConfig>;
pub type IndexKey = CoreIndexKey<MatrixCoreTypeConfig>;
pub trait IntoExecuteReference {
    fn into(self) -> ExecuteReference;
}

impl IntoExecuteReference for OwnedRoomId
{
    fn into(self) -> ExecuteReference {
        ExecuteReference::Room(self)
    }
}

impl IntoExecuteReference for &RoomId
{
    fn into(self) -> ExecuteReference {
        ExecuteReference::Room(self.to_owned())
    }
}

impl IntoExecuteReference for OwnedEventId
{
    fn into(self) -> ExecuteReference {
        ExecuteReference::Model(self)
    }
}


impl IntoExecuteReference for &EventId
{
    fn into(self) -> ExecuteReference {
        ExecuteReference::Model(self.to_owned())
    }
}

impl IntoExecuteReference for ModelType
{
    fn into(self) -> ExecuteReference {
        ExecuteReference::ModelType(self)
    }
}

impl IntoExecuteReference for ExecuteReference
{
    fn into(self) -> ExecuteReference {
        self
    }
}

impl IntoExecuteReference for IndexKey
{
    fn into(self) -> ExecuteReference {
        ExecuteReference::Index(self)
    }
}

impl IntoExecuteReference for SectionIndex
{
    fn into(self) -> ExecuteReference {
        ExecuteReference::Index(IndexKey::Section(self))
    }
}

impl IntoExecuteReference for SpecialListsIndex
{
    fn into(self) -> ExecuteReference {
        ExecuteReference::Index(IndexKey::Special(self))
    }
}