use matrix_sdk::ruma::events::macros::EventContent;
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct ThreePidRecord {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    submit_url: Option<String>,
    session_id: String,
    passphrase: String,
}

impl ThreePidRecord {
    pub fn new(submit_url: Option<String>, session_id: String, passphrase: String) -> Self {
        ThreePidRecord {
            submit_url,
            session_id,
            passphrase,
        }
    }

    pub fn submit_url(&self) -> Option<String> {
        self.submit_url.clone()
    }

    pub fn session_id(&self) -> String {
        self.session_id.clone()
    }

    pub fn passphrase(&self) -> String {
        self.passphrase.clone()
    }
}

#[derive(Clone, Debug, Deserialize, Serialize, EventContent)]
#[ruma_event(type = "global.acter.dev.three_pid", kind = GlobalAccountData)]
pub struct ThreePidContent {
    pub via_email: BTreeMap<String, ThreePidRecord>,
    pub via_phone: BTreeMap<String, ThreePidRecord>,
}
