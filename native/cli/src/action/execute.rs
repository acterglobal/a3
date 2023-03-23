use crate::config::{LoginConfig, ENV_ROOM};
use acter_core::matrix_sdk::ruma::OwnedRoomId;
use anyhow::Result;
use clap::Parser;
use futures::{pin_mut, StreamExt};
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
    pub room: OwnedRoomId,
    #[clap(flatten)]
    pub login: LoginConfig,

    #[clap()]
    pub templates: Vec<PathBuf>,
}

impl ExecuteOpts {
    pub async fn run(&self) -> Result<()> {
        let mut user = self.login.client().await?;

        let sync_state = user.start_sync();

        let mut is_synced = sync_state.first_synced_rx().expect("note yet read");
        while is_synced.next().await != Some(true) {} // let's wait for it to have synced

        for tmpl_path in self.templates.iter() {
            let template = std::fs::read_to_string(tmpl_path)?;

            let tmpl_engine = user.template_engine(&template).await?;
            let exec_stream = tmpl_engine.execute()?;
            pin_mut!(exec_stream);
            while let Some(i) = exec_stream.next().await {
                i?
            }
        }
        Ok(())
    }
}
