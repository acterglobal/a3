use matrix_sdk::Session;
use serde::{Deserialize, Serialize};

/// Extensive Restore Token for Effektio Sessions
#[derive(Serialize, Deserialize)]
pub struct RestoreToken {
    /// Was this registered per guest-account?
    is_guest: bool,
    /// Server homebase url
    homeurl: String,
    /// Session to hand to client
    session: Session,
}
