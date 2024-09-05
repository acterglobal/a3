use matrix_sdk_base::ruma::{OwnedDeviceId, OwnedUserId};
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

    // legacy that isn’t used anymore
    #[serde(default, skip_serializing)]
    #[allow(dead_code)]
    /// a separate local cache path
    media_cache_base_path: Option<String>,
}

impl RestoreToken {
    pub fn serialized(
        session: CustomAuthSession,
        homeurl: Url,
        is_guest: bool,
        db_passphrase: Option<String>,
    ) -> serde_json::Result<String> {
        serde_json::to_string(&RestoreToken {
            session,
            homeurl,
            is_guest,
            db_passphrase,
            media_cache_base_path: None,
        })
    }
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
