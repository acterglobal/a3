use anyhow::Result;
use effektio::api::{guest_client, login_new_client};
use tempfile::TempDir;

#[tokio::test]
#[ignore]
async fn can_guest_login() -> Result<()> {
    let _ = env_logger::try_init();
    let tmp_dir = TempDir::new()?;
    let _client = guest_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        option_env!("HOMESERVER")
            .unwrap_or("http://localhost:8118")
            .to_string(),
    )
    .await?;
    Ok(())
}


#[tokio::test]
#[ignore]
async fn sisko_can_login() -> Result<()> {
    let _ = env_logger::try_init();
    let tmp_dir = TempDir::new()?;
    let _client = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@sisko:ds9.effektio.org".to_owned(),
        "sisko".to_owned(),
    )
    .await?;
    Ok(())
}


#[tokio::test]
#[ignore]
async fn kyra_can_login() -> Result<()> {
    let _ = env_logger::try_init();
    let tmp_dir = TempDir::new()?;
    let _client = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@kyra:ds9.effektio.org".to_owned(),
        "kyra".to_owned(),
    )
    .await?;
    Ok(())
}
