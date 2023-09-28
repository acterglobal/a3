use acter::api::{login_new_client, CreateConvoSettingsBuilder};
use anyhow::{Context, Result};
use futures::stream::StreamExt;
use tempfile::TempDir;
use tokio::time::{sleep, Duration};
use tracing::error;

use crate::utils::default_user_password;

#[tokio::test]
#[ignore = "test runs forever in github runner, it works well in local synapse :("]
async fn sisko_sends_rich_text_to_kyra() -> Result<()> {
    let _ = env_logger::try_init();

    let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME")
        .unwrap_or("localhost")
        .to_string();
    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL")
        .unwrap_or("http://localhost:8118")
        .to_string();

    // initialize sisko's client
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
    let sisko_syncer = sisko.start_sync();
    let mut sisko_synced = sisko_syncer.first_synced_rx();
    while sisko_synced.next().await != Some(true) {} // let's wait for it to have synced

    // sisko creates room and invites kyra
    let settings = CreateConvoSettingsBuilder::default()
        .invites(vec![format!("@kyra:{homeserver_name}").try_into()?])
        .build()?;
    let sisko_kyra_dm_id = sisko.create_convo(Box::new(settings)).await?;

    // initialize kyra's client
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
    let kyra_syncer = kyra.start_sync();
    let mut first_synced = kyra_syncer.first_synced_rx();
    while first_synced.next().await != Some(true) {} // let's wait for it to have synced

    // kyra accepts invitation from sisko
    let invited = kyra.get_room(&sisko_kyra_dm_id).unwrap();
    let mut delay = 2;
    while let Err(e) = invited.join().await {
        sleep(Duration::from_secs(delay)).await;
        delay *= 2;
        if delay > 3600 {
            error!("Can't join room {} ({:?})", invited.room_id(), e);
            break;
        }
    }

    // sisko sends the formatted text message to kyra
    let convo = sisko
        .convo_typed(&sisko_kyra_dm_id)
        .await
        .context("chat not found")?;
    let _event_id = convo
        .send_formatted_message("**Hello**".to_string())
        .await?;

    // kyra receives the formatted text message from sisko
    let convo = kyra
        .convo_typed(&sisko_kyra_dm_id)
        .await
        .context("chat not found")?;

    if let Some(msg) = convo.latest_message() {
        if let Some(event_item) = msg.event_item() {
            if let Some(text_desc) = event_item.text_desc() {
                if let Some(formatted) = text_desc.formatted_body() {
                    let idx = formatted.find("<strong>Hello</strong>");
                    assert!(idx.is_some(), "formatted body not found");
                }
            }
        }
    }

    Ok(())
}
