use acter::api::CreateConvoSettingsBuilder;
use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::tests::activities::{all_activities_observer, assert_triggered_with_latest_activity};

use super::setup_accounts;

#[tokio::test]
async fn test_space_parent() -> Result<()> {
    let _ = env_logger::try_init();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) = setup_accounts("space-parent").await?;

    let settings = CreateConvoSettingsBuilder::default().build()?;
    let parent_room_id = admin.create_convo(Box::new(settings)).await?;
    let mut act_obs = all_activities_observer(&observer).await?;
    let room = admin.room(room_id.to_string()).await?;
    let room_activities = observer.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    // ensure it was sent
    let parent_event_id = room
        .add_parent_room(parent_room_id.to_string(), false)
        .await?;
    let via = vec!["localhost".to_owned()];

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
        parent_event_id,
        "event id should match"
    );
    assert_eq!(activity.sender_id_str(), admin.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id);
    assert_eq!(activity.room_id_str(), room_id);
    assert_eq!(activity.type_str(), "spaceParent");
    let ts: u64 = meta.origin_server_ts.get().into();
    assert_eq!(activity.origin_server_ts(), ts);

    // check the content of activity
    let content = activity
        .space_parent_content()
        .expect("not a space parent event");

    let room_id = content.room_id().ok();
    assert_eq!(room_id, Some(parent_room_id), "room id should be present");

    assert_eq!(
        content.via_change().as_deref(),
        Some("Set"),
        "change of via should be set"
    );
    assert_eq!(
        content.via_new_val(),
        via.clone(),
        "new val of via is invalid"
    );

    assert_eq!(
        content.canonical_change().as_deref(),
        Some("Set"),
        "change of canonical should be set"
    );
    assert!(
        !content.canonical_new_val(),
        "new val of canonical is invalid"
    );

    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;

    Ok(())
}
