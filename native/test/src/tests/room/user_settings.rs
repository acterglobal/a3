use acter::UserRoomSettings;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user_with_random_space;
use anyhow::{bail, Result};

fn is_default(settings: &UserRoomSettings) {
    assert!(!settings.has_seen_suggested());
    assert!(settings.include_cal_sync());
}

#[tokio::test]
async fn has_seen_suggested_test() -> Result<()> {
    let (mut user, room_id) = random_user_with_random_space("has_seen_suggested").await?;

    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    let room = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.room(room_id.to_string()).await }
    })
    .await?;

    let user_room_settings = room.user_settings().await?;

    is_default(&user_room_settings); // default is set as expected

    let subscriber = user_room_settings.subscribe();
    user_room_settings.set_has_seen_suggested(true).await?;

    // wait for update to come through
    Retry::spawn(retry_strategy.clone(), || async {
        if subscriber.is_empty() {
            bail!("not been alerted to reload");
        }
        Ok(())
    })
    .await?;

    // fetch again
    let user_room_settings = room.user_settings().await?;

    assert!(user_room_settings.has_seen_suggested()); // change is found

    // -- reset

    let subscriber = user_room_settings.subscribe();
    user_room_settings.set_has_seen_suggested(false).await?;

    // wait for update to come through
    Retry::spawn(retry_strategy, || async {
        if subscriber.is_empty() {
            bail!("not been alerted to reload");
        }
        Ok(())
    })
    .await?;

    // fetch again
    let user_room_settings = room.user_settings().await?;

    assert!(!user_room_settings.has_seen_suggested()); // change is found

    is_default(&user_room_settings); // we are back to default
    Ok(())
}

#[tokio::test]
async fn include_cal_sync_test() -> Result<()> {
    let (mut user, room_id) = random_user_with_random_space("include_cal_sync").await?;

    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    let room = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.room(room_id.to_string()).await }
    })
    .await?;

    let user_room_settings = room.user_settings().await?;

    is_default(&user_room_settings); // default is set as expected

    let subscriber = user_room_settings.subscribe();
    user_room_settings.set_include_cal_sync(false).await?;

    // wait for update to come through
    Retry::spawn(retry_strategy.clone(), || async {
        if subscriber.is_empty() {
            bail!("not been alerted to reload");
        }
        Ok(())
    })
    .await?;

    // fetch again
    let user_room_settings = room.user_settings().await?;

    assert!(!user_room_settings.include_cal_sync()); // change is found

    // -- reset

    let subscriber = user_room_settings.subscribe();
    user_room_settings.set_include_cal_sync(true).await?;

    // wait for update to come through
    Retry::spawn(retry_strategy, || async {
        if subscriber.is_empty() {
            bail!("not been alerted to reload");
        }
        Ok(())
    })
    .await?;

    // fetch again
    let user_room_settings = room.user_settings().await?;

    assert!(user_room_settings.include_cal_sync()); // change is found

    is_default(&user_room_settings); // we are back to default

    Ok(())
}
