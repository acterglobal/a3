use acter::{api::login_new_client, Client};
use acter_core::matrix_sdk::ruma::OwnedUserId;
use anyhow::Result;
use clap::Parser;
use dialoguer::{theme::ColorfulTheme, Password};
use std::path::PathBuf;

pub const ENV_USER: &str = "ACTER_USER";
pub const ENV_PASSWORD: &str = "ACTER_PASSWORD";

/// Generic Login Configuration helper
#[derive(Parser, Debug)]
pub struct LoginConfig {
    /// Fully qualified @SOMETHING:server.tld username.
    #[clap(
        short = 'u',
        long = "user",
        env = ENV_USER
    )]
    login_username: OwnedUserId,

    #[clap(
        short = 'p',
        long = "password",
        env = ENV_PASSWORD
    )]
    login_password: Option<String>,
}

impl LoginConfig {
    pub async fn client(&self, path: PathBuf) -> Result<Client> {
        let theme = ColorfulTheme::default();
        let username = self.login_username.clone();
        tracing::info!("Logging in as {}", username);
        let password = match self.login_password {
            Some(ref pw) => pw.clone(),
            None => Password::with_theme(&theme)
                .with_prompt(format!("Password for {username:} :"))
                .interact()?,
        };
        let default_homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME")
            .unwrap_or("acter.global")
            .to_string();
        let default_homeserver_url = option_env!("DEFAULT_HOMESERVER_URL")
            .unwrap_or("https://matrix.acter.global")
            .to_string();

        let client = login_new_client(
            String::from(path.to_string_lossy()),
            username.to_string(),
            password,
            default_homeserver_name,
            default_homeserver_url,
            Some("acter-tui".to_owned()),
        )
        .await?;

        Ok(client)
    }
}

#[derive(Parser, Debug)]
#[clap(author, version, about, long_about = None)]
pub struct ActerTuiConfig {
    /// Logging configuration
    #[clap(short, long, default_value = "acter_tui=info,warn")]
    pub log: String,

    /// Start logger in fullscreen
    #[clap(long)]
    pub fullscreen_logs: bool,

    /// drop and delete any existing database
    #[clap(short, long)]
    pub fresh: bool,

    /// use .local as the starting point for the database
    #[clap(long)]
    pub local: bool,

    /// The action to perform
    #[clap(flatten)]
    pub login: LoginConfig,
}
