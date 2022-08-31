use anyhow::Result;
use effektio::login_new_client;
use std::time::Duration;
use tempfile::TempDir;
use tokio::time::sleep;

#[tokio::test]
async fn load_pending_invitation() -> Result<()> {
    let _ = env_logger::try_init();

    let tmp_dir = TempDir::new()?;
    let sisko = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@sisko:ds9.effektio.org".to_owned(),
        "sisko".to_owned(),
    )
    .await?;
    let sisko_syncer = sisko.start_sync();

    let tmp_dir = TempDir::new()?;
    let kyra = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@kyra:ds9.effektio.org".to_owned(),
        "kyra".to_owned(),
    )
    .await?;
    let kyra_syncer = kyra.start_sync();

    sleep(Duration::from_secs(3)).await;

    let invitations = kyra.pending_invitations();
    println!("invitations: {:?}", invitations);

    Ok(())
}
