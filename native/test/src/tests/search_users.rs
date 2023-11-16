use acter::{
    api::login_new_client,
    ruma_common::{OwnedUserId, UserId},
};
use anyhow::Result;
use futures::stream::StreamExt;
use tempfile::TempDir;

use crate::utils::default_user_password;

#[tokio::test]
async fn search_users() -> Result<()> {
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
    let syncer = sisko.start_sync();
    let mut synced = syncer.first_synced_rx();
    while synced.next().await != Some(true) {} // let's wait for it to have synced

    let profiles = sisko.search_users("m".to_string()).await?;
    let users = profiles
        .iter()
        .map(|profile| profile.user_id())
        .collect::<Vec<OwnedUserId>>();
    let miles_id = UserId::parse(format!("@miles:{}", homeserver_name))?;
    assert!(users.contains(&miles_id), "miles not found");
    let morn_id = UserId::parse(format!("@morn:{}", homeserver_name))?;
    assert!(users.contains(&morn_id), "morn not found");

    let fields = homeserver_name
        .split('.')
        .map(|x| x.to_string())
        .collect::<Vec<String>>();
    let mut segments = vec![];
    for field in fields {
        segments.push(field);
        let term = format!("miles:{}", segments.join("."));
        let profiles = sisko.search_users(term.clone()).await?;
        assert!(!profiles.is_empty(), "search by {} not working", term);
    }

    Ok(())
}
