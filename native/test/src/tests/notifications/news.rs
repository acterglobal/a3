use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_users_with_random_space;

#[tokio::test]
async fn news_notification() -> Result<()> {
    let _ = env_logger::try_init();
    let (users, room_id) = random_users_with_random_space("news_notifications", 1).await?;

    let mut user = users[0].clone();
    let mut second = users[1].clone();

    second.install_default_acter_push_rules().await?;

    let sync_state1 = user.start_sync();
    sync_state1.await_has_synced_history().await?;

    let sync_state2 = second.start_sync();
    sync_state2.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let main_space = Retry::spawn(retry_strategy, || async {
        let spaces = user.spaces().await?;
        if spaces.len() != 1 {
            bail!("space not found");
        }
        Ok(spaces.first().cloned().expect("space found"))
    })
    .await?;

    let text_draft = user.text_plain_draft("This is text slide".to_owned());
    let event_id = {
        let mut draft = main_space.news_draft()?;
        draft.add_slide(Box::new(text_draft.into())).await?;
        draft.send().await?
    };
    tracing::trace!("draft sent event id: {}", event_id);

    let notifications = second
        .get_notification_item(room_id.to_string(), event_id.to_string())
        .await?;

    assert_eq!(notifications.push_style(), "news");
    assert_eq!(notifications.target_url(), format!("/updates/{event_id}"));

    Ok(())
}
