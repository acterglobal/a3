use anyhow::Result;
use effektio::api::login_new_client;
use tempfile::TempDir;

#[tokio::test]
async fn sisko_posts_news() -> Result<()> {
    let _ = env_logger::try_init();
    let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME")
        .unwrap_or("localhost")
        .to_string();
    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL")
        .unwrap_or("http://localhost:8118")
        .to_string();
    let tmp_dir = TempDir::new()?;
    let client = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "@sisko".to_string(),
        "sisko".to_string(),
        homeserver_name.clone(),
        homeserver_url,
        Some("KYRA_DEV".to_string()),
    )
    .await?;
    client
        .sync_once(Default::default())
        .await
        .expect("sync works");
    let ops = client
        .get_group(format!("#ops:{homeserver_name}"))
        .await
        .expect("Promenade exists");

    let news_draft = ops
        .news_draft()
        .expect("we are in, we can create news drafts");
    news_draft.add_text("This is a simple text example".to_string())?;
    let event_id = news_draft.send().await?;
    client
        .sync_once(Default::default())
        .await
        .expect("sync works");
    // we should have
    let latest_news_item = client
        .latest_news()
        .await?
        .into_iter()
        .next()
        .expect("we should have a news item");
    // assert_eq!(
    //     latest_news_item.event_id(),
    //     event_id,
    //     "Latest news isn't the item, we just sent",
    // );

    Ok(())
}
