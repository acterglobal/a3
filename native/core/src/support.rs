use ruma_common::{OwnedDeviceId, OwnedUserId};
use serde::{Deserialize, Serialize};
use url::Url;

/// Extensive Restore Token for Acter Sessions
#[derive(Serialize, Deserialize, Debug)]
pub struct RestoreToken {
    /// Was this registered per guest-account?
    pub is_guest: bool,
    /// Server homebase url
    pub homeurl: Url,
    /// Session to hand to client
    pub session: CustomAuthSession,
    /// a passphrase for the underlying database
    pub db_passphrase: Option<String>,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct CustomAuthSession {
    /// user id for login
    pub user_id: OwnedUserId,
    /// device id for login
    pub device_id: OwnedDeviceId,
    /// access token for login
    pub access_token: String,
}
