use matrix_sdk::Session;
use serde::{Deserialize, Serialize};
use url::Url;

/// Extensive Restore Token for Acter Sessions
#[derive(Serialize, Deserialize)]
pub struct RestoreToken {
    /// Was this registered per guest-account?
    pub is_guest: bool,
    /// Server homebase url
    pub homeurl: Url,
    /// Session to hand to client
    pub session: Session,
}
