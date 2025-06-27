use super::{AccountData, ModelType, ObjectId, RoomId, Timestamp, UserId};

// Configure the types related as one
pub trait TypeConfig {
    type RoomId: RoomId;
    type ObjectId: ObjectId;
    type ModelType: ModelType;
    type AccountData: AccountData;
    type UserId: UserId;
    type Timestamp: Timestamp;
}
