use anyhow::Result;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user_with_random_convo;

#[tokio::test]
async fn save_message_draft() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("save_message_draft").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        user.convo(room_id.to_string()).await
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let body = "Hi, everyone";
    let draft_type = "new";
    convo
        .save_msg_draft(body.to_owned(), None, draft_type.to_owned(), None)
        .await?;

    let draft = convo
        .msg_draft()
        .await?
        .draft()
        .expect("draft should be present");
    assert_eq!(draft.draft_type(), draft_type);
    assert_eq!(draft.plain_text(), body);

    Ok(())
}
