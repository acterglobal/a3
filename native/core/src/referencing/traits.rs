use serde::{Deserialize, Serialize};

pub trait ObjectId =
    Serialize + for<'de> Deserialize<'de> + std::fmt::Debug + AsRef<str> + Clone + Sized;
pub trait RoomId =
    Serialize + for<'de> Deserialize<'de> + std::fmt::Debug + AsRef<str> + Clone + Sized;
pub trait ModelType =
    Serialize + for<'de> Deserialize<'de> + std::fmt::Debug + AsRef<str> + Clone + Sized;
pub trait AccountData =
Serialize + for<'de> Deserialize<'de> + std::fmt::Debug + AsRef<str> + Clone + Sized;


// Configure the types related as one
pub trait TypeConfig {
    type RoomId: RoomId;
    type ObjectId: ObjectId;
    type ModelType: ModelType;
    type AccountData: AccountData;
}