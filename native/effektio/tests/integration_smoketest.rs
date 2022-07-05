use anyhow::Result;
use effektio::api::guest_client;

#[tokio::test(flavor = "multi_thread", worker_threads = 4)]
#[ignore]
async fn can_guest_login() -> Result<()> {
    let client = guest_client(
        "test".to_string(),
        option_env!("HOMESERVER")
            .unwrap_or("http://localhost:8008")
            .to_string(),
    )
    .await?;
    Ok(())
}
