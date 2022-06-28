use effektio::api::guest_client;
use anyhow::Result;


#[tokio::test(flavor = "multi_thread", worker_threads = 4)]
#[ignore]
async fn can_guest_login() -> Result<()> {
    let client = guest_client("test".to_string(), env!("HOMESERVER").to_string()).await?;
    Ok(())
}