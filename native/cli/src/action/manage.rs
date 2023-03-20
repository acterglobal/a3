use crate::config::LoginConfig;
use acter_core::spaces::CreateSpaceSettingsBuilder;
use anyhow::Result;
use clap::Parser;
use futures::StreamExt;

#[derive(clap::Subcommand, Debug, Clone)]
pub enum Action {
    /// List rooms
    CreateOnboardingSpace,
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
        let mut client = self.login.client().await?;
        let settings = Box::new(
            CreateSpaceSettingsBuilder::default()
                .name(format!("{}'s onboarding space", client.user_id()?))
                .build()?,
        );

        let room_id = client.create_acter_group(settings).await?;

        tracing::info!(" - Syncing -");
        let sync_state = client.start_sync();

        let mut is_synced = sync_state.first_synced_rx().expect("note yet read");
        while is_synced.next().await != Some(true) {} // let's wait for it to have synced
        tracing::info!(" - First Sync finished - ");

        let room = client.get_group(room_id.to_string()).await?;

        room.create_onboarding_data().await?;

        println!("Onboarding Space created: {room_id}");

        client.logout().await?;
        Ok(())
    }
}
