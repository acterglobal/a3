use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user_with_random_space;
use anyhow::{bail, Result};

#[tokio::test]
async fn history_sync_restart() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("history_sync__restart").await?;
    let state_sync = user.start_sync();
    let sync_controller = user.start_simple_sync().await?;
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.space(room_id.to_string()).await }
    })
    .await?;

    let space = user.space(room_id.to_string()).await?;
    let mut draft = space.news_draft()?;
    let text_draft = user.text_markdown_draft("## This is a simple text".to_owned());
    draft.add_slide(Box::new(text_draft.into())).await?;
    draft.send().await?;

    let space_cl = space.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let inner_space = space_cl.clone();
        async move {
            if inner_space.latest_news_entries(1).await?.len() != 1 {
                bail!("news not found");
            }
            Ok(())
        }
    })
    .await?;

    // stop syncing
    state_sync.cancel();
    sync_controller.cancel();

    let slides = space.latest_news_entries(1).await?;
    let final_entry = slides.first().unwrap();
    let news_sub = final_entry.subscribe();

    // restarting sync. We do _not_ expect to see the subscribe issue anything
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    assert!(news_sub.is_empty(), "We received updates about the entry");

    Ok(())
}
