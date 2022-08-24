use anyhow::Result;
use async_broadcast::TryRecvError;
use effektio::api::login_new_client;
use futures::stream::StreamExt;
use tempfile::TempDir;

#[tokio::test]
async fn kyra_detects_sisko_typing() -> Result<()> {
    let _ = env_logger::try_init();

    let tmp_dir = TempDir::new()?;
    let sisko = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@sisko:ds9.effektio.org".to_owned(),
        "sisko".to_owned(),
    )
    .await?;
    let sisko_syncer = sisko.start_sync();
    let mut first_synced = sisko_syncer.get_first_synced_rx().expect("note yet read");
    while first_synced.next().await != Some(true) {} // let's wait for it to have synced
    let group = sisko
        .get_group("#ops:ds9.effektio.org".to_owned())
        .await
        .expect("sisko should belong to ops");
    let sent = group.typing_notice(true).await?;
    println!("sent: {:?}", sent);

    let tmp_dir = TempDir::new()?;
    let kyra = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@kyra:ds9.effektio.org".to_owned(),
        "kyra".to_owned(),
    )
    .await?;
    let kyra_syncer = kyra.start_sync();
    let kyra_tnc = kyra.get_typing_notification_controller().await?;
    let mut event_rx0 = kyra_tnc.get_event_rx().unwrap();
    let mut event_rx1 = kyra_tnc.get_event_rx().unwrap();

    loop {
        match event_rx1.try_recv() {
            Ok(event) => {
                println!("received: {:?}", event);
                break;
            }
            Err(TryRecvError::Closed) => {
                println!("receiver closed");
            }
            Err(TryRecvError::Empty) => {
                // println!("receiver empty");
            }
            Err(TryRecvError::Overflowed(n)) => {
                println!("receiver overflowed: {:?}", n);
            }
        }
    }

    Ok(())
}
