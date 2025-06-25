use serde::{Deserialize, Serialize};

pub trait ObjectId =
    Serialize + for<'de> Deserialize<'de> + std::fmt::Debug + AsRef<str> + Clone + Sized;
pub trait RoomId =
    Serialize + for<'de> Deserialize<'de> + std::fmt::Debug + AsRef<str> + Clone + Sized;
pub trait ModelType =
    Serialize + for<'de> Deserialize<'de> + std::fmt::Debug + AsRef<str> + Clone + Sized;
pub trait AccountData =
Serialize + for<'de> Deserialize<'de> + std::fmt::Debug + AsRef<str> + Clone + Sized;
