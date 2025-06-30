use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user_with_random_space;

#[tokio::test]
async fn test_room_create() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_space("room-create").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;
    let _activities = user.all_activities()?;
    let room = user.room(room_id.to_string()).await?;
    let room_activities = user.activities_for_room(room_id.to_string())?;

    // wait for the event to come in
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let activity = Retry::spawn(retry_strategy, || async {
        // when creating a room, matrix-sdk receives the several events in a batch, and room create event is not the latest activity
        // we need to check the several activities to find the room create event
        let m = room_activities.get_ids(0, 10).await?;
        for idx in m.clone() {
            let activity = user.activity(idx.clone()).await?;
            if activity.type_str() == "roomCreate" {
                return Ok(activity);
            }
        }
        bail!("no room create activity found");
    })
    .await?;

    // external API check
    let meta = activity.event_meta();
    assert_eq!(activity.sender_id_str(), user.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id);
    assert_eq!(activity.room_id_str(), room.room_id_str());
    let ts: u64 = meta.origin_server_ts.get().into();
    assert_eq!(activity.origin_server_ts(), ts);

    // check the content of activity
    let _content = activity
        .room_create_content()
        .expect("not a room create event");

    Ok(())
}
