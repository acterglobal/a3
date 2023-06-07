use acter::api::{
    guest_client, login_new_client, login_new_client_under_config, login_with_token_under_config,
    make_client_config,
};
use anyhow::Result;
use tempfile::TempDir;

use crate::utils::default_user_password;

#[tokio::test]
async fn guest_can_login() -> Result<()> {
    let _ = env_logger::try_init();
    let should_test = option_env!("GUEST_ACCESS").unwrap_or("false");
    if should_test == "1" || should_test == "true" {
        let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME")
            .unwrap_or("localhost")
            .to_string();
        let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL")
            .unwrap_or("http://localhost:8118")
            .to_string();

        let tmp_dir = TempDir::new()?;
        let _client = guest_client(
            tmp_dir.path().to_str().expect("always works").to_string(),
            homeserver_name,
            homeserver_url,
            Some("GUEST_DEV".to_string()),
        )
        .await?;
    } else {
        log::warn!("Skipping guest test. To run set env var GUEST_ACCESS=1");
    }
    Ok(())
}

#[tokio::test]
async fn sisko_can_login() -> Result<()> {
    let _ = env_logger::try_init();
    let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME")
        .unwrap_or("localhost")
        .to_string();
    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL")
        .unwrap_or("http://localhost:8118")
        .to_string();

    let tmp_dir = TempDir::new()?;
    let _client = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "@sisko".to_string(),
        default_user_password("sisko"),
        homeserver_name,
        homeserver_url,
        Some("SISKO_DEV".to_string()),
    )
    .await?;
    Ok(())
}

#[tokio::test]
async fn kyra_can_login() -> Result<()> {
    let _ = env_logger::try_init();
    let tmp_dir = TempDir::new()?;
    let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME")
        .unwrap_or("localhost")
        .to_string();
    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL")
        .unwrap_or("http://localhost:8118")
        .to_string();

    let _client = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "@kyra".to_string(),
        default_user_password("kyra"),
        homeserver_name,
        homeserver_url,
        Some("KYRA_DEV".to_string()),
    )
    .await?;
    Ok(())
}

#[tokio::test]
async fn kyra_can_restore() -> Result<()> {
    let _ = env_logger::try_init();
    let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME")
        .unwrap_or("localhost")
        .to_string();
    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL")
        .unwrap_or("http://localhost:8118")
        .to_string();
    let tmp_dir = TempDir::new()?;
    let base_path = tmp_dir.path().to_str().expect("always works").to_string();
    let (config, user_id) =
        make_client_config(base_path, "@kyra", &homeserver_name, &homeserver_url).await?;

    let (token, user_id) = {
        let client = login_new_client_under_config(
            config.clone(),
            user_id,
            default_user_password("kyra"),
            Some("KYRA_DEV".to_string()),
        )
        .await?;
        let token = client.restore_token().await?;
        let user_id = client
            .user_id()
            .expect("username missing after login. weird");
        (token, user_id)
    };

    let client = login_with_token_under_config(token, config).await?;
    let uid = client
        .user_id()
        .expect("Login by token seems to be not working");
    assert_eq!(uid, user_id);
    Ok(())
}
