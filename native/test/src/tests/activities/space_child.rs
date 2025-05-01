use acter::api::CreateConvoSettingsBuilder;
use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use super::setup_accounts;

#[tokio::test]
async fn test_space_child() -> Result<()> {
    let _ = env_logger::try_init();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) = setup_accounts("space-child").await?;

    let settings = CreateConvoSettingsBuilder::default().build()?;
    let child_room_id = admin.create_convo(Box::new(settings)).await?;

    let room = admin.room(room_id.to_string()).await?;
    let room_activities = observer.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    // ensure it was sent
    let child_event_id = room
        .add_child_room(child_room_id.to_string(), None, true)
        .await?;
    let via = vec!["localhost".to_owned()];

    activities_listenerd.recv().await?; // await for it have been coming in

    // wait for the event to come in
    let cl = observer.clone();
    let activity = Retry::spawn(retry_strategy, move || {
        let room_activities = room_activities.clone();
        let cl = cl.clone();
        async move {
            let m = room_activities.get_ids(0, 1).await?;
            let Some(id) = m.first().cloned() else {
                bail!("no latest room activity found");
            };
            cl.activity(id).await
        }
    })
    .await?;

    // external API check
    let meta = activity.event_meta();
    assert_eq!(
        meta.event_id.clone(),
        child_event_id,
        "event id should match"
    );
    assert_eq!(activity.sender_id_str(), admin.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id.to_string());
    assert_eq!(activity.room_id_str(), room_id.to_string());
    assert_eq!(activity.type_str(), "spaceChild");
    let ts: u64 = meta.origin_server_ts.get().into();
    assert_eq!(activity.origin_server_ts(), ts);

    // check the content of activity
    let content = activity
        .space_child_content()
        .expect("not a space child event");

    let room_id = content.room_id().ok();
    assert_eq!(room_id, Some(child_room_id), "room id should be present");

    assert_eq!(
        content.via_change(),
        Some("Set".to_owned()),
        "change of via should be set"
    );
    assert_eq!(
        content.via_new_val(),
        via.clone(),
        "new val of via is invalid"
    );

    assert_eq!(
        content.order_change(),
        None,
        "change of order should be none"
    );
    assert_eq!(content.order_new_val(), None, "new val of order is invalid");

    assert_eq!(
        content.suggested_change(),
        Some("Set".to_owned()),
        "change of suggested should be set"
    );
    assert!(
        content.suggested_new_val(),
        "new val of suggested is invalid"
    );

    Ok(())
}
