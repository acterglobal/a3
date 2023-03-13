use crate::utils::random_user_with_random_space;
use anyhow::Result;

#[tokio::test]
async fn onboarding_is_created() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("onboarding").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;
    let group = user.get_group(room_id.to_string()).await?;

    assert_eq!(
        group.task_lists().await?.len(),
        0,
        "Why are there tasks in our fresh space!?!"
    );

    group.create_onboarding_data().await?;

    assert_eq!(group.task_lists().await?.len(), 1, "Task lists not found");

    Ok(())
}
