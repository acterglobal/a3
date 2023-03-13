use anyhow::Result;
use clap::{crate_version, Parser};
use dialoguer::theme::ColorfulTheme;
use dialoguer::Password;

use acter_core::matrix_sdk::ruma::OwnedUserId;
use acter_core::matrix_sdk::{Client, ClientBuilder};

use crate::action::Action;

use tracing::warn;

pub const ENV_USER: &str = "ACTER_USER";
pub const ENV_PASSWORD: &str = "ACTER_PASSWORD";
pub const ENV_ROOM: &str = "ACTER_ROOM";

/// Generic Login Configuration helper
#[derive(Parser, Debug)]
pub struct LoginConfig {
    /// Fully qualified @SOMETHING:server.tld username.
    #[clap(
        short = 'u',
        long = "user",
        value_hint = clap::ValueHint::Username,
        env = ENV_USER
    )]
    login_username: OwnedUserId,
    #[clap(env = ENV_PASSWORD)]
    login_password: Option<String>,
}

async fn default_client_config() -> Result<ClientBuilder> {
    Ok(Client::builder().user_agent(format!("acter-cli/{}", crate_version!())))
}

impl LoginConfig {
    pub async fn client(&self) -> Result<Client> {
        let theme = ColorfulTheme::default();
        let username = self.login_username.clone();
        warn!("Logging in as {}", username);
        let password = match self.login_password {
            Some(ref pw) => pw.clone(),
            _ => Password::with_theme(&theme)
                .with_prompt(format!("Password for {username:} :"))
                .interact()?,
        };

        let client = default_client_config()
            .await?
            .server_name(username.server_name())
            .build()
            .await?;

        client
            .login_username(username.localpart(), &password)
            .send()
            .await?;

        Ok(client)
    }
}

#[derive(Parser, Debug)]
#[clap(author, version, about, long_about = None)]
pub struct ActerCliConfig {
    /// Logging configuration
    #[clap(short, long, default_value = "acter_cli=info,warn")]
    pub log: String,

    /// The action to perform
    #[clap(subcommand)]
    pub action: Action,
}
