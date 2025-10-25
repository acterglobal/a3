use core::hash::Hash;
use serde::{Deserialize, Serialize};

pub trait ActerKeyable = AsRef<str>;
pub trait ActerCoreSerial =
    Serialize + for<'de> Deserialize<'de> + std::fmt::Debug + Clone + Sized + Send + Sync;

pub trait ActerCoreHash = Hash + Eq + PartialEq + Send + Sync;

pub trait ObjectId = ActerCoreSerial + ActerKeyable + ActerCoreHash;
pub trait RoomId = ActerCoreSerial + ActerKeyable + ActerCoreHash;
pub trait ModelType = ActerCoreSerial + ActerKeyable + ActerCoreHash;
pub trait AccountData = ActerCoreSerial + ActerKeyable + ActerCoreHash;
pub trait UserId = ActerCoreSerial + ActerKeyable + ActerCoreHash;
pub trait Timestamp = ActerCoreSerial + Ord + PartialOrd;

pub trait RedactionReason = ActerCoreSerial;
