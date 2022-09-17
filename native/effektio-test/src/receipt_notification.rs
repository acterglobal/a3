use anyhow::Result;
use effektio::api::login_new_client;
use futures::stream::StreamExt;
use tempfile::TempDir;

#[tokio::test]
async fn sisko_detects_kyra_read() -> Result<()> {
    let _ = env_logger::try_init();

    let tmp_dir = TempDir::new()?;
    let sisko = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@sisko:ds9.effektio.org".to_owned(),
        "sisko".to_owned(),
    )
    .await?;
    let sisko_syncer = sisko.start_sync();
    let mut sisko_synced = sisko_syncer.get_first_synced_rx().expect("note yet read");
    while sisko_synced.next().await != Some(true) {} // let's wait for it to have synced
    let sisko_group = sisko
        .get_group("#ops:ds9.effektio.org".to_owned())
        .await
        .expect("sisko should belong to ops");
    let event_id = sisko_group
        .send_plain_message("Hi, everyone".to_owned())
        .await?;

    let tmp_dir = TempDir::new()?;
    let kyra = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@kyra:ds9.effektio.org".to_owned(),
        "kyra".to_owned(),
    )
    .await?;
    let kyra_syncer = kyra.start_sync();
    let mut kyra_synced = kyra_syncer.get_first_synced_rx().expect("note yet read");
    while kyra_synced.next().await != Some(true) {} // let's wait for it to have synced
    let kyra_group = kyra
        .get_group("#ops:ds9.effektio.org".to_owned())
        .await
        .expect("kyra should belong to ops");
    kyra_group.read_receipt(event_id).await?;

    let mut event_rx = kyra.receipt_notification_event_rx().unwrap();
    loop {
        match event_rx.try_next() {
            Ok(Some(event)) => {
                let mut found = false;
                for record in event.get_receipt_records() {
                    if record.get_user_id().as_str() == "@kyra:ds9.effektio.org" {
                        found = true;
                        break;
                    }
                }
                if found {
                    println!("received: {:?}", event);
                    break;
                }
            }
            Ok(None) => {
                println!("received: none");
            }
            Err(e) => {}
        }
    }

    Ok(())
}
