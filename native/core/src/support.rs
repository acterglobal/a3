use matrix_sdk::Session;
use serde::{Deserialize, Serialize};

/// Extensive Restore Token for Effektio Sessions
#[derive(Serialize, Deserialize)]
pub struct RestoreToken {
    /// Was this registered per guest-account?
    pub is_guest: bool,
    /// Server homebase url
    pub homeurl: String,
    /// Session to hand to client
    pub session: Session,
}
