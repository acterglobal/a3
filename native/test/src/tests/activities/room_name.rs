use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::tests::activities::{all_activities_observer, assert_triggered_with_latest_activity};

use super::setup_accounts;

#[tokio::test]
async fn test_room_name() -> Result<()> {
    let _ = env_logger::try_init();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) = setup_accounts("room-name").await?;
    let mut act_obs = all_activities_observer(&observer).await?;
    let room = admin.room(room_id.to_string()).await?;
    let room_activities = observer.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    // ensure it was sent
    let new_name = "Babbling Room";
    let old_name = room.name();
    let name_event_id = room.set_name(new_name.to_owned()).await?;

    activities_listenerd.recv().await?; // await for it have been coming in

    // wait for the event to come in
    let activity = Retry::spawn(retry_strategy, || async {
        let m = room_activities.get_ids(0, 1).await?;
        let Some(id) = m.first().cloned() else {
            bail!("no latest room activity found");
        };
        observer.activity(id).await
    })
    .await?;

    // external API check
    let meta = activity.event_meta();
    assert_eq!(
        meta.event_id.clone(),
        name_event_id,
        "event id should match"
    );
    assert_eq!(activity.sender_id_str(), admin.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id);
    assert_eq!(activity.room_id_str(), room_id);
    assert_eq!(activity.type_str(), "roomName");
    let ts: u64 = meta.timestamp.get().into();
    assert_eq!(activity.origin_server_ts(), ts);

    // check the content of activity
    let content = activity.room_name_content().expect("not a room name event");

    assert_eq!(
        content.change().as_deref(),
        Some("Changed"),
        "room name should be changed"
    );
    assert_eq!(
        content.new_val(),
        new_name,
        "new val of room name is invalid"
    );
    assert_eq!(
        content.old_val(),
        old_name,
        "old val of room name is invalid"
    );

    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;

    Ok(())
}
