use anyhow::Result;
use effektio::api::{guest_client, login_new_client, login_with_token};
use tempfile::TempDir;

#[tokio::test]
async fn sisko_posts_news() -> Result<()> {
    let _ = env_logger::try_init();
    let tmp_dir = TempDir::new()?;
    let client = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@sisko:ds9.effektio.org".to_owned(),
        "sisko".to_owned(),
    )
    .await?;
    client
        .sync_once(Default::default())
        .await
        .expect("sync works");
    let news = client.latest_news().await?;
    let promenade = client
        .get_group("#promenade:ds9.effektio.org".to_owned())
        .await
        .expect("Promenade exists");

    Ok(())
}
