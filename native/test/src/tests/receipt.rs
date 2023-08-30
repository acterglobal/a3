use acter::api::login_new_client;
use anyhow::Result;
use futures::stream::StreamExt;
use tempfile::TempDir;

use crate::utils::default_user_password;

#[tokio::test]
async fn sisko_detects_kyra_read() -> Result<()> {
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
    let mut sisko_synced = sisko_syncer.first_synced_rx();
    while sisko_synced.next().await != Some(true) {} // let's wait for it to have synced
    let sisko_space = sisko
        .get_space(format!("#ops:{homeserver_name}"))
        .await
        .expect("sisko should belong to ops");
    let event_id = sisko_space
        .send_plain_message("Hi, everyone".to_string())
        .await?;

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
    let kyra_space = kyra
        .get_space(format!("#ops:{homeserver_name}"))
        .await
        .expect("kyra should belong to ops");
    kyra_space.read_receipt(event_id.to_string()).await?;

    let mut event_rx = kyra.receipt_event_rx().unwrap();
    loop {
        match event_rx.try_next() {
            Ok(Some(event)) => {
                let mut found = false;
                for record in event.receipt_records() {
                    if record.seen_by() == format!("@kyra:{homeserver_name}") {
                        found = true;
                        break;
                    }
                }
                if found {
                    println!("received: {event:?}");
                    break;
                }
            }
            Ok(None) => {
                println!("received: none");
            }
            Err(_e) => {}
        }
    }

    Ok(())
}
