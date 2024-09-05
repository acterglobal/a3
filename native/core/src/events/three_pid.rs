use matrix_sdk_base::ruma::events::macros::EventContent;
use matrix_sdk_base::ruma::OwnedClientSecret;
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct ThreePidRecord {
    session_id: String,
    passphrase: OwnedClientSecret,
}

impl ThreePidRecord {
    pub fn new(session_id: String, passphrase: OwnedClientSecret) -> Self {
        ThreePidRecord {
            session_id,
            passphrase,
        }
    }

    pub fn session_id(&self) -> String {
        self.session_id.clone()
    }

    pub fn passphrase(&self) -> OwnedClientSecret {
        self.passphrase.clone()
    }
}

#[derive(Clone, Debug, Deserialize, Serialize, EventContent)]
#[ruma_event(type = "global.acter.dev.three_pid", kind = GlobalAccountData)]
pub struct ThreePidContent {
    pub via_email: BTreeMap<String, ThreePidRecord>,
    pub via_phone: BTreeMap<String, ThreePidRecord>,
}
