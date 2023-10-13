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
    /// the target basepath
    pub base_path: String,
}


#[derive(Serialize, Deserialize)]
pub(crate) struct BackwardsCompRestoreToken {
    /// Was this registered per guest-account?
    pub is_guest: bool,
    /// Server homebase url
    pub homeurl: Url,
    /// Session to hand to client
    pub session: CustomAuthSession,
    /// a passphrase for the underlying database
    pub db_passphrase: Option<String>,
    /// the target basepath
    pub base_path: Option<String>,
}

impl BackwardsCompRestoreToken {
    pub(crate) fn into_token(self, fallback_base_path: String) -> RestoreToken {
        RestoreToken {
            is_guest: self.is_guest,
            homeurl: self.homeurl,
            session: self.session,
            db_passphrase: self.db_passphrase,
            base_path: self.base_path.unwrap_or(fallback_base_path)
        }
    }
}

pub fn convert_old_restore_token(restore_token: String, base_path: String) -> crate::Result<String> {
    let token: BackwardsCompRestoreToken = serde_json::from_str(&restore_token)?;
    Ok(serde_json::to_string(&token.into_token(base_path))?)
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
