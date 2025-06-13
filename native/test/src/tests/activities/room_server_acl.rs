use acter_core::util::do_vecs_match;
use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::tests::activities::{all_activities_observer, assert_triggered_with_latest_activity};

use super::setup_accounts;

#[tokio::test]
async fn test_room_server_acl() -> Result<()> {
    let _ = env_logger::try_init();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("room-server-acl").await?;

    let mut act_obs = all_activities_observer(&observer).await?;

    let room = admin.room(room_id.to_string()).await?;
    let room_activities = observer.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    // ensure it was sent
    let allow = vec!["*".to_owned()];
    let deny = vec!["1.1.1.1".to_owned()];
    let acl_event_id = room
        .set_server_acl(
            true,
            serde_json::to_string(&allow)?,
            serde_json::to_string(&deny)?,
        )
        .await?;

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
    assert_eq!(meta.event_id.clone(), acl_event_id, "event id should match");
    assert_eq!(activity.sender_id_str(), admin.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id);
    assert_eq!(activity.room_id_str(), room_id);
    assert_eq!(activity.type_str(), "roomServerAcl");
    let ts: u64 = meta.origin_server_ts.get().into();
    assert_eq!(activity.origin_server_ts(), ts);

    // check the content of activity
    let content = activity
        .room_server_acl_content()
        .expect("not a room server acl event");

    assert_eq!(
        content.allow_ip_literals_change().as_deref(),
        Some("Set"),
        "allow ip literals in room server acl should be set"
    );
    assert!(
        content.allow_ip_literals_new_val(),
        "new val of allow ip literals in room server acl is invalid"
    );

    assert_eq!(
        content.allow_change().as_deref(),
        Some("Set"),
        "allow in room server acl should be set"
    );
    assert!(
        do_vecs_match(content.allow_new_val().as_slice(), allow.as_slice()),
        "new val of allow in room server acl is invalid"
    );

    assert_eq!(
        content.deny_change().as_deref(),
        Some("Set"),
        "deny in room server acl should be set"
    );
    assert!(
        do_vecs_match(content.deny_new_val().as_slice(), deny.as_slice()),
        "new val of deny in room server acl is invalid"
    );

    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;

    Ok(())
}
