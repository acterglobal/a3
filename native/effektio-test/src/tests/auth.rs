use anyhow::Result;
use effektio::api::{guest_client, login_new_client, login_with_token};
use tempfile::TempDir;

#[tokio::test]
async fn guest_can_login() -> Result<()> {
    let _ = env_logger::try_init();
    let tmp_dir = TempDir::new()?;
    let _client = guest_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        option_env!("DEFAULT_HOMESERVER_URL")
            .unwrap_or("http://localhost:8118")
            .to_string(),
        Some("GUEST_DEV".to_string()),
    )
    .await?;
    Ok(())
}

#[tokio::test]
async fn sisko_can_login() -> Result<()> {
    let _ = env_logger::try_init();
    let tmp_dir = TempDir::new()?;
    let _client = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "sisko".to_string(),
        "sisko".to_string(),
        Some("SISKO_DEV".to_string()),
    )
    .await?;
    Ok(())
}

#[tokio::test]
async fn kyra_can_login() -> Result<()> {
    let _ = env_logger::try_init();
    let tmp_dir = TempDir::new()?;
    let _client = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "kyra".to_string(),
        "kyra".to_string(),
        Some("KYRA_DEV".to_string()),
    )
    .await?;
    Ok(())
}

#[tokio::test]
#[ignore = "drop isn't sufficient to close the database"]
async fn kyra_can_restore() -> Result<()> {
    let _ = env_logger::try_init();
    let tmp_dir = TempDir::new()?;
    let (token, user_id) = {
        let client = login_new_client(
            tmp_dir.path().to_str().expect("always works").to_string(),
            "kyra".to_string(),
            "kyra".to_string(),
            Some("KYRA_DEV".to_string()),
        )
        .await?;
        let token = client.restore_token().await?;
        let user_id = client.user_id()?;
        drop(client);
        (token, user_id)
    };

    let client = login_with_token(
        tmp_dir.path().to_str().expect("always works").to_string(),
        token,
    )
    .await?;
    assert_eq!(client.user_id()?, user_id);
    Ok(())
}
