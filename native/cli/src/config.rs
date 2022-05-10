use anyhow::Result;
use clap::{crate_version, Parser};
use dialoguer::theme::ColorfulTheme;
use dialoguer::Password;

use effektio_core::matrix_sdk::ruma::OwnedUserId;
use effektio_core::matrix_sdk::{Client, ClientBuilder};

use crate::action::Action;

use log::warn;

pub const ENV_USER: &str = "EFFEKTIO_USER";
pub const ENV_PASSWORD: &str = "EFFEKTIO_PASSWORD";
pub const ENV_ROOM: &str = "EFFEKTIO_ROOM";

/// Generic Login Configuration helper
#[derive(Parser, Debug)]
pub struct LoginConfig {
    /// Fully qualified @SOMETHING:server.tld username.
    #[clap(
        short = 'u',
        long = "user",
        value_hint = clap::ValueHint::Username,
        parse(try_from_str),
        env = ENV_USER
    )]
    login_username: OwnedUserId,
    #[clap(env = ENV_PASSWORD)]
    login_password: Option<String>,
}

async fn default_client_config() -> Result<ClientBuilder> {
    Ok(Client::builder().user_agent(&format!("effektio-cli/{}", crate_version!())))
}

impl LoginConfig {
    pub async fn client(&self) -> Result<Client> {
        let theme = ColorfulTheme::default();
        let username = self.login_username.clone();
        warn!("Logging in as {}", username);
        let password = match self.login_password {
            Some(ref pw) => pw.clone(),
            _ => Password::with_theme(&theme)
                .with_prompt(format!("Password for {:} :", username))
                .interact()?,
        };

        let client = default_client_config()
            .await?
            .user_id(&username)
            .build()
            .await?;

        client
            .login(username.localpart(), &password, None, None)
            .await?;

        Ok(client)
    }
}

#[derive(Parser, Debug)]
#[clap(author, version, about, long_about = None)]
pub struct EffektioCliConfig {
    /// Logging configuration
    #[clap(short, long, default_value = "warn")]
    pub log: String,

    /// The action to perform
    #[clap(subcommand)]
    pub action: Action,
}
