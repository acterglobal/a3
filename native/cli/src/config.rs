use anyhow::Result;
use clap::{crate_version, Parser};
use dialoguer::theme::ColorfulTheme;
use dialoguer::Password;

use effektio_core::matrix_sdk::ruma::{RoomId, UserId};
use effektio_core::matrix_sdk::{config::ClientConfig, Client};

use log::warn;
use std::path::PathBuf;

/// Generic Login Configuration helper
#[derive(Parser, Debug)]
pub struct LoginConfig {
    /// Fully qualified @SOMETHING:server.tld username.
    #[clap(
        short = 'u',
        long = "user",
        value_hint = clap::ValueHint::Username,
        parse(try_from_str),
        env = "EFFEKTIO_USER"
    )]
    login_username: Box<UserId>,
    #[clap(env = "EFFEKTIO_PASSWORD")]
    login_password: Option<String>,
}

async fn default_client_config() -> Result<ClientConfig> {
    Ok(ClientConfig::new().await?.user_agent(&format!("effektio-cli/{}", crate_version!()))?)
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

        let client =
            Client::new_from_user_id_with_config(&username, default_client_config().await?).await?;

        client
            .login(username.localpart(), &password, None, None)
            .await?;

        Ok(client)
    }
}

/// Posting a news item to a given room
#[derive(Parser, Debug)]
pub struct PostNews {
    /// The room you want to post the news to
    #[clap(short, long, parse(try_from_str), env = "EFFEKTIO_ROOM")]
    pub room: Box<RoomId>,
    #[clap(flatten)]
    pub login: LoginConfig,

    /// Path to images to post
    #[clap(short, long, value_hint = clap::ValueHint::FilePath)]
    pub image: Vec<PathBuf>,

    #[clap(short, long)]
    /// Path to video(s) to post
    pub video: Vec<PathBuf>,

    /// Text to posh
    #[clap(short, long)]
    pub text: Vec<String>,

    /// Font/Text color
    #[clap(short, long)]
    pub color: Option<String>,

    /// Background color
    #[clap(short, long)]
    pub background: Option<String>,
}

/// Posting a news item to a given room
#[derive(Parser, Debug)]
pub struct FetchNews {
    /// The room you want to post the news to
    #[clap(short, long, parse(try_from_str), env = "EFFEKTIO_ROOM")]
    pub room: Box<RoomId>,
    #[clap(flatten)]
    pub login: LoginConfig,
}

/// Posting a news item to a given room
#[derive(Parser, Debug)]
pub struct Manage {
    /// The room you want to post the news to
    #[clap(short, long, parse(try_from_str), env = "EFFEKTIO_ROOM")]
    pub room: Box<RoomId>,
    #[clap(flatten)]
    pub login: LoginConfig,
}

#[derive(clap::Subcommand, Debug)]
pub enum Action {
    /// Post News to a room
    PostNews(PostNews),
    /// Fetch News of the use
    FetchNews(FetchNews),
    /// Room Management
    Manage(Manage),
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
