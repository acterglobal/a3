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
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        user.space(room_id.to_string()).await
    })
    .await?;

    let space = user.space(room_id.to_string()).await?;
    let text_draft = user.text_markdown_draft("## This is a simple text".to_owned());
    space
        .news_draft()?
        .add_slide(Box::new(text_draft.into()))
        .send()
        .await?;

    Retry::spawn(retry_strategy, || async {
        if space.latest_news_entries(1).await?.len() != 1 {
            bail!("news not found");
        }
        Ok(())
    })
    .await?;

    // stop syncing
    state_sync.cancel();
    user.sync_controller().cancel().await?;

    let slides = space.latest_news_entries(1).await?;
    let final_entry = slides.first().expect("first slide should be available");
    let news_sub = final_entry.subscribe();

    // restarting sync. We do _not_ expect to see the subscribe issue anything
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    assert!(news_sub.is_empty(), "We received updates about the entry");

    Ok(())
}
