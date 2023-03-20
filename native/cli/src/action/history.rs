use crate::config::{LoginConfig, ENV_ROOM};
use acter_core::matrix_sdk::{
    room::{Messages, MessagesOptions},
    ruma::OwnedRoomId,
};
use anyhow::{bail, Result};
use clap::Parser;
use futures::StreamExt;

#[derive(Parser, Debug)]
pub struct HistoryOpts {
    #[clap(flatten)]
    pub login: LoginConfig,

    /// The room you want to see the history of messages of
    #[clap(env = ENV_ROOM)]
    pub room: OwnedRoomId,
}

impl HistoryOpts {
    pub async fn run(&self) -> Result<()> {
        let mut client = self.login.client().await?;

        tracing::info!(" - Syncing -");
        let sync_state = client.start_sync();

        let mut is_synced = sync_state.first_synced_rx().expect("note yet read");
        while is_synced.next().await != Some(true) {} // let's wait for it to have synced
        tracing::info!(" - First Sync finished - ");

        let Some(room) = client.get_room(self.room.as_ref()) else {
            bail!("Room not found");
        };

        let mut msg_options = MessagesOptions::forward().from(None);
        msg_options.limit = 100u32.into();

        loop {
            let Messages {
                end,
                chunk,
                state: _,
                ..
            } = room.messages(msg_options).await?;

            for msg in chunk {
                let evt = msg.event;
                println!("- {}", evt.into_json());
            }

            if end.is_some() {
                msg_options = MessagesOptions::forward().from(end.as_deref());
            } else {
                // how do we want to understand this case?
                tracing::trace!(room_id = ?room.room_id(), "Done loading");
                break;
            }
        }
        client.logout().await?;
        Ok(())
    }
}
