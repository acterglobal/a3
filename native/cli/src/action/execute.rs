use crate::config::{LoginConfig, ENV_ROOM};
use anyhow::{bail, Result};
use clap::{crate_version, Parser, Subcommand};
use effektio::{
    platform::sanitize,
    testing::{ensure_user, wait_for},
    Client as EfkClient, CreateGroupSettingsBuilder,
};
use effektio_core::{
    models::EffektioModel,
    ruma::{api::client::room::Visibility, OwnedUserId},
};
use matrix_sdk_base::store::{MemoryStore, StoreConfig};
use matrix_sdk_sled::make_store_config;
use std::collections::HashMap;
use std::path::PathBuf;

#[derive(Parser, Debug)]
pub struct ExecuteOpts {
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

    /// The room you want to post the news to
    #[clap(short, long, env = ENV_ROOM)]
    pub room: Box<effektio_core::ruma::RoomId>,
    #[clap(flatten)]
    pub login: LoginConfig,

    #[clap()]
    pub templates: Vec<PathBuf>,
}
