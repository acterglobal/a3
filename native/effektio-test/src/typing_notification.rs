use anyhow::Result;
use effektio::api::login_new_client;
use std::time::Duration;
use tempfile::TempDir;
use tokio::time::sleep;

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
    let group = sisko.get_group("#ops:ds9.effektio.org".to_owned()).await.unwrap();
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
    let mut rx = kyra_syncer.get_ephemeral_event_rx().unwrap();

    while let Some(event) = rx.try_next()? {
        println!("received: {:?}", event);
    }

    Ok(())
}
