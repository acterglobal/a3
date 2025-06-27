use serde::{Deserialize, Serialize};

pub trait ActerKeyable = AsRef<str>;
use std::hash::Hash;
pub trait ActerCoreSerial =
    Serialize + for<'de> Deserialize<'de> + std::fmt::Debug + Clone + Sized + Send + Sync;

pub trait ObjectId = ActerCoreSerial + ActerKeyable + Eq + PartialEq + Hash;
pub trait RoomId = ActerCoreSerial + ActerKeyable;
pub trait ModelType = ActerCoreSerial + ActerKeyable;
pub trait AccountData = ActerCoreSerial + ActerKeyable;
pub trait UserId = ActerCoreSerial + ActerKeyable;
pub trait Timestamp = ActerCoreSerial + Ord + PartialOrd;
