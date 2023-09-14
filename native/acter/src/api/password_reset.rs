use acter_core::events::password_reset::{PasswordResetContent, PasswordResetViaEmail, PasswordResetViaPhone};
use anyhow::{Context, Result};
use std::ops::Deref;

use super::{account::Account, RUNTIME};

#[derive(Clone)]
pub struct PasswordReset {
    inner: PasswordResetContent,
}

impl Deref for PasswordReset {
    type Target = PasswordResetContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl PasswordReset {
    fn via_email(&self) -> Option<PasswordResetViaEmail> {
        self.inner.via_email()
    }

    fn via_phone(&self) -> Option<PasswordResetViaPhone> {
        self.inner.via_phone()
    }
}

impl Account {
    pub async fn set_password_reset_via_email(
        &self,
        submit_url: Option<String>,
        session_id: String,
        passphrase: String,
    ) -> Result<bool> {
        let account = self.deref().clone();
        RUNTIME
            .spawn(async move {
                let data = PasswordResetViaEmail::new(
                    submit_url.clone(),
                    session_id.clone(),
                    passphrase.clone(),
                );
                let content = PasswordResetContent::new(Some(data), None);
                account
                    .set_account_data(content)
                    .await
                    .context("Setting account data failed")?;
                Ok(true)
            })
            .await?
    }

    pub async fn set_password_reset_via_phone(
        &self,
        submit_url: Option<String>,
        session_id: String,
        passphrase: String,
    ) -> Result<bool> {
        let account = self.deref().clone();
        RUNTIME
            .spawn(async move {
                let data = PasswordResetViaPhone::new(
                    submit_url.clone(),
                    session_id.clone(),
                    passphrase.clone(),
                );
                let content = PasswordResetContent::new(None, Some(data));
                account
                    .set_account_data(content)
                    .await
                    .context("Setting account data failed")?;
                Ok(true)
            })
            .await?
    }

    pub async fn get_password_reset(&self) -> Result<PasswordReset> {
        let account = self.deref().clone();
        RUNTIME
            .spawn(async move {
                if let Some(raw_content) = account
                    .account_data::<PasswordResetContent>()
                    .await
                    .context("getting of PasswordResetContent from account data was failed")?
                {
                    let inner = raw_content
                        .deserialize()
                        .context("deserialization of PasswordResetContent was failed")?;
                    return Ok(PasswordReset { inner });
                }
                Ok(PasswordReset {
                    inner: PasswordResetContent::new(None, None),
                })
            })
            .await?
    }
}
