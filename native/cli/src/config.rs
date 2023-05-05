use acter::api::{login_new_client, login_with_token, Client};
use anyhow::{Context, Result};
use clap::{crate_version, Parser};
use dialoguer::{theme::ColorfulTheme, Password};
use std::path::PathBuf;

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

    /// Force a fresh login, drop all existing datastore
    #[clap(long)]
    force_login: bool,

    /// Do not store the access token on disk
    #[clap(long)]
    dont_store_token: bool,

    /// Use the path for reading (and optionall storing) the access token
    #[clap(long)]
    token_path: Option<PathBuf>,
}

impl LoginConfig {
    pub async fn client(&self) -> Result<Client> {
        let theme = ColorfulTheme::default();
        let username = self.login_username.clone();
        tracing::warn!("Logging in as {}", username);
        let base_path = format!(".local/{username}/");

        if self.force_login && std::path::Path::new(&base_path).exists() {
            std::fs::remove_dir_all(&base_path)?;
        }
        // FIXME: this should be encrypted.
        let token_path_string = self
            .token_path
            .clone()
            .unwrap_or_else(|| PathBuf::from(format!("{base_path}/access_token.json")));
        let access_token_path = std::path::Path::new(&token_path_string);
        if access_token_path.exists() && access_token_path.is_file() {
            tracing::info!(
                "Reusing previous access token from {}",
                token_path_string.display()
            );
            let token = std::fs::read_to_string(access_token_path)
                .context("reading access token file failed")?;
            return login_with_token(base_path, token).await;
        }

        let password = match self.login_password {
            Some(ref pw) => pw.clone(),
            None => Password::with_theme(&theme)
                .with_prompt(format!("Password for {username:} :"))
                .interact()?,
        };

        let client = login_new_client(
            base_path,
            username.clone(),
            password,
            self.server_name.clone(),
            self.homeserver.clone(),
            Some(format!("acter-cli/{}", crate_version!())),
        )
        .await?;

        if !self.dont_store_token {
            match client.restore_token().await {
                Ok(token) => {
                    std::fs::write(access_token_path, token)?;
                }
                Err(e) => tracing::error!(error = ?e, "No access token found on client."),
            }
        }
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
