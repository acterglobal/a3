use serde::{Deserialize, Serialize};

#[derive(Eq, PartialEq, Ord, PartialOrd, Hash, Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "strum", derive(strum::Display, strum::EnumString))]
#[cfg_attr(feature = "strum", strum(serialize_all = "snake_case"))]
#[repr(u8)]
pub enum SpecialListsIndex {
    MyOpenTasks,
    MyDoneTasks,
    InvitedTo,
    #[cfg(any(test, feature = "testing"))]
    Test1,
    #[cfg(any(test, feature = "testing"))]
    Test2,
    #[cfg(any(test, feature = "testing"))]
    Test3,
}
