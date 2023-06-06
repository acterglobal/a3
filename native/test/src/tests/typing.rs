use acter::api::login_new_client;
use anyhow::Result;
use futures::stream::StreamExt;
use tempfile::TempDir;

use crate::utils::default_user_password;

#[tokio::test]
async fn kyra_detects_sisko_typing() -> Result<()> {
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
    let sisko_syncer = sisko.start_sync();
    let mut first_synced = sisko_syncer.first_synced_rx().expect("not yet read");
    while first_synced.next().await != Some(true) {} // let's wait for it to have synced
    let space = sisko
        .get_space(format!("#ops:{homeserver_name}"))
        .await
        .expect("sisko should belong to ops");
    let sent = space.typing_notice(true).await?;
    println!("sent: {sent:?}");

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
    let mut event_rx = kyra.typing_event_rx().unwrap();

    loop {
        match event_rx.try_next() {
            Ok(Some(event)) => {
                println!("received: {event:?}");
                break;
            }
            Ok(None) => {
                println!("received: none");
            }
            Err(_e) => {}
        }
    }

    Ok(())
}
