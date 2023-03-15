use anyhow::{Context, Result};
use matrix_sdk::{media::MediaFormat, Account as MatrixAccount};

use super::{api::FfiBuffer, RUNTIME};

#[derive(Clone, Debug)]
pub struct Account {
    account: MatrixAccount,
    user_id: String,
}

impl std::ops::Deref for Account {
    type Target = MatrixAccount;
    fn deref(&self) -> &MatrixAccount {
        &self.account
    }
}

impl Account {
    pub fn new(account: MatrixAccount, user_id: String) -> Self {
        Account { account, user_id }
    }

    pub fn user_id(&self) -> String {
        self.user_id.clone()
    }

    pub async fn display_name(&self) -> Result<String> {
        let account = self.account.clone();
        RUNTIME
            .spawn(async move {
                let display_name = account
                    .get_display_name()
                    .await?
                    .context("No User ID found")?;
                Ok(display_name)
            })
            .await?
    }

    pub async fn set_display_name(&self, new_name: String) -> Result<bool> {
        let account = self.account.clone();
        RUNTIME
            .spawn(async move {
                let name = if new_name.is_empty() {
                    None
                } else {
                    Some(new_name.as_str())
                };
                account.set_display_name(name).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn avatar(&self) -> Result<FfiBuffer<u8>> {
        let account = self.account.clone();
        RUNTIME
            .spawn(async move {
                let data = account
                    .get_avatar(MediaFormat::File)
                    .await?
                    .context("No avatar URL given")?;
                Ok(FfiBuffer::new(data))
            })
            .await?
    }

    pub async fn set_avatar(&self, c_type: String, data: Vec<u8>) -> Result<bool> {
        let account = self.account.clone();
        RUNTIME
            .spawn(async move {
                let new_url = account.upload_avatar(&c_type.parse()?, data).await?;
                Ok(true)
            })
            .await?
    }
}
