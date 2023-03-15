use acter::api::{login_new_client, Client};
use anyhow::Result;
use clap::{crate_version, Parser};
use dialoguer::theme::ColorfulTheme;
use dialoguer::Password;

use crate::action::Action;

pub const ENV_USER: &str = "ACTER_USER";
pub const ENV_PASSWORD: &str = "ACTER_PASSWORD";
pub const ENV_ROOM: &str = "ACTER_ROOM";

/// Generic Login Configuration helper
#[derive(Parser, Debug)]
pub struct LoginConfig {
    /// the URL to the homeserver are we running against
    #[clap(
        long = "homeserver-url",
        env = "DEFAULT_HOMESERVER_URL",
        default_value = "http://localhost:8118"
    )]
    pub homeserver: String,
    /// name of that homeserver
    #[clap(
        long = "homeserver-name",
        env = "DEFAULT_HOMESERVER_NAME",
        default_value = "localhost"
    )]
    pub server_name: String,
    /// Fully qualified @SOMETHING:server.tld username.
    #[clap(
        short = 'u',
        long = "user",
        value_hint = clap::ValueHint::Username,
        env = ENV_USER
    )]
    login_username: String,
    #[clap(long="password", env = ENV_PASSWORD)]
    login_password: Option<String>,
}

impl LoginConfig {
    pub async fn client(&self) -> Result<Client> {
        let theme = ColorfulTheme::default();
        let username = self.login_username.clone();
        tracing::warn!("Logging in as {}", username);
        let password = match self.login_password {
            Some(ref pw) => pw.clone(),
            _ => Password::with_theme(&theme)
                .with_prompt(format!("Password for {username:} :"))
                .interact()?,
        };
        login_new_client(
            format!(".local/{username}/"),
            username.clone(),
            password,
            self.server_name.clone(),
            self.homeserver.clone(),
            Some(format!("acter-cli/{}", crate_version!())),
        )
        .await
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
