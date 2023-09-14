use matrix_sdk::ruma::events::macros::EventContent;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct PasswordResetViaEmail {
    submit_url: Option<String>,
    session_id: String,
    passphrase: String,
}

impl PasswordResetViaEmail {
    pub fn new(submit_url: Option<String>, session_id: String, passphrase: String) -> Self {
        PasswordResetViaEmail { submit_url, session_id, passphrase }
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

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct PasswordResetViaPhone {
    submit_url: Option<String>,
    session_id: String,
    passphrase: String,
}

impl PasswordResetViaPhone {
    pub fn new(submit_url: Option<String>, session_id: String, passphrase: String) -> Self {
        PasswordResetViaPhone { submit_url, session_id, passphrase }
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
#[ruma_event(type = "global.acter.dev.password_reset", kind = GlobalAccountData)]
pub struct PasswordResetContent {
    via_email: Option<PasswordResetViaEmail>,
    via_phone: Option<PasswordResetViaPhone>,
}

impl PasswordResetContent {
    pub fn new(
        via_email: Option<PasswordResetViaEmail>,
        via_phone: Option<PasswordResetViaPhone>,
    ) -> Self {
        PasswordResetContent {
            via_email,
            via_phone,
        }
    }

    pub fn via_email(&self) -> Option<PasswordResetViaEmail> {
        self.via_email.clone()
    }

    pub fn via_phone(&self) -> Option<PasswordResetViaPhone> {
        self.via_phone.clone()
    }
}
