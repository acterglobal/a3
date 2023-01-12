use std::path::PathBuf;

use anyhow::Result;
use clap::Parser;
use dialoguer::theme::ColorfulTheme;
use dialoguer::Password;

use effektio::api::login_new_client;
use effektio::Client;
use effektio_core::matrix_sdk::ruma::OwnedUserId;

pub const ENV_USER: &str = "EFFEKTIO_USER";
pub const ENV_PASSWORD: &str = "EFFEKTIO_PASSWORD";

/// Generic Login Configuration helper
#[derive(Parser, Debug)]
pub struct LoginConfig {
    /// Fully qualified @SOMETHING:server.tld username.
    #[clap(
        short = 'u',
        long = "user",
        parse(try_from_str),
        env = ENV_USER
    )]
    login_username: OwnedUserId,
    #[clap(
        short = 'p',
        long = "password",
        parse(try_from_str),
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
            _ => Password::with_theme(&theme)
                .with_prompt(format!("Password for {username:} :"))
                .interact()?,
        };

        let client = login_new_client(
            String::from(path.to_string_lossy()),
            username.to_string(),
            password,
            Some("effektio-tui".to_owned()),
        )
        .await?;

        Ok(client)
    }
}

#[derive(Parser, Debug)]
#[clap(author, version, about, long_about = None)]
pub struct EffektioTuiConfig {
    /// Logging configuration
    #[clap(short, long, default_value = "effektio_tui=info,warn")]
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
