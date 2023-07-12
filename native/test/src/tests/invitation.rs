use acter::api::login_new_client;
use anyhow::Result;
use futures::{pin_mut, StreamExt};
use std::time::Duration;
use tempfile::TempDir;
use tokio::time::sleep;

use crate::utils::default_user_password;

#[tokio::test]
async fn load_pending_invitation() -> Result<()> {
    let _ = env_logger::try_init();

    let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME")
        .unwrap_or("localhost")
        .to_string();
    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL")
        .unwrap_or("http://localhost:8118")
        .to_string();

    let tmp_dir = TempDir::new()?;
    let mut sisko = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "@sisko".to_string(),
        default_user_password("sisko"),
        homeserver_name.clone(),
        homeserver_url.clone(),
        Some("SISKO_DEV".to_string()),
    )
    .await?;
    let _sisko_syncer = sisko.start_sync();

    let tmp_dir = TempDir::new()?;
    let mut kyra = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "@kyra".to_string(),
        default_user_password("kyra"),
        homeserver_name.clone(),
        homeserver_url.clone(),
        Some("KYRA_DEV".to_string()),
    )
    .await?;
    let _kyra_syncer = kyra.start_sync();

    sleep(Duration::from_secs(3)).await;

    // sisko creates room and invites kyra
    // let settings = acter::api::CreateConvoSettingsBuilder::default().build()?;
    // let room_id = sisko.create_convo(settings).await?;
    // println!("created room id: {}", room_id);

    // sleep(Duration::from_secs(3)).await;

    // let room = sisko.get_joined_room(room_id.as_str().try_into()?)?;
    // let kyra_id = acter::matrix_sdk::ruma::user_id!("@kyra");
    // room.invite_user_by_id(kyra_id).await?;

    // sleep(Duration::from_secs(3)).await;

    let receiver = kyra.invitations_rx();
    pin_mut!(receiver);
    loop {
        match receiver.next().await {
            Some(invitations) => {
                println!("received: {invitations:?}");
                break;
            }
            None => {
                println!("received: none");
            }
        }
    }

    sleep(Duration::from_secs(3)).await;

    Ok(())
}
