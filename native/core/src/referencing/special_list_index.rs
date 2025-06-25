use serde::{Deserialize, Serialize};
use strum::{Display, EnumString};

#[derive(
    Eq, PartialEq, Ord, PartialOrd, Hash, Debug, Clone, Display, EnumString, Serialize, Deserialize,
)]
#[strum(serialize_all = "snake_case")]
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
