use acter_core::spaces::CreateSpaceSettingsBuilder;
use anyhow::{Context, Result};
use clap::Parser;
use futures::StreamExt;
use matrix_sdk::ruma::OwnedRoomId;

use crate::config::LoginConfig;

#[derive(clap::Subcommand, Debug, Clone)]
pub enum Action {
    /// List rooms
    CreateOnboardingSpace,
    /// Mark the space as an acter space
    MarkAsActerSpace { room_id: OwnedRoomId },
}

/// Posting a news item to a given room
#[derive(Parser, Debug)]
pub struct Manage {
    #[clap(flatten)]
    pub login: LoginConfig,

    #[clap(subcommand)]
    pub action: Action,
}

impl Manage {
    pub async fn run(&self) -> Result<()> {
        match self.action {
            Action::CreateOnboardingSpace => self.run_create_onboarding_space().await,
            Action::MarkAsActerSpace { ref room_id } => self.run_marking_space(room_id).await,
        }
    }

    async fn run_marking_space(&self, room_id: &OwnedRoomId) -> Result<()> {
        let mut client = self.login.client().await?;
        tracing::info!(" - Syncing -");
        let sync_state = client.start_sync();

        let mut is_synced = sync_state.first_synced_rx().context("not yet read")?;
        while is_synced.next().await != Some(true) {} // let's wait for it to have synced
        tracing::info!(" - First Sync finished - ");

        let space = client.get_space(room_id.to_string()).await?;

        if !space.is_space() {
            tracing::warn!("{room_id} is not a space. quitting.");
            return Ok(());
        } else if space.is_acter_space().await {
            tracing::warn!("{room_id} is already an acter space. quitting.");
            return Ok(());
        }

        space.set_acter_space_states().await?;

        tracing::info!("States sent");

        // FIXME DO SOMETHING
        Ok(())
    }

    async fn run_create_onboarding_space(&self) -> Result<()> {
        let mut client = self.login.client().await?;
        let settings = CreateSpaceSettingsBuilder::default()
            .name(format!("{}'s onboarding space", client.user_id()?))
            .build()?;

        let room_id = client.create_acter_space(Box::new(settings)).await?;

        tracing::info!(" - Syncing -");
        let sync_state = client.start_sync();

        let mut is_synced = sync_state.first_synced_rx().context("not yet read")?;
        while is_synced.next().await != Some(true) {} // let's wait for it to have synced
        tracing::info!(" - First Sync finished - ");

        let room = client.get_space(room_id.to_string()).await?;

        room.create_onboarding_data().await?;

        println!("Onboarding Space created: {room_id}");
        Ok(())
    }
}
