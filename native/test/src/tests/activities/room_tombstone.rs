use acter_core::activities::ActivityContent;
use anyhow::{bail, Result};
use nanoid::nanoid;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use super::setup_accounts;

#[tokio::test]
async fn test_room_tombstone() -> Result<()> {
    let _ = env_logger::try_init();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("room-tombstone").await?;

    let room = admin.room(room_id.to_string()).await?;
    let room_activities = observer.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    // ensure it was sent
    let body = "This room was upgraded to the other version";
    let id = gen_id(18);
    let replacement_room_id = format!("!{}:localhost", id);
    let tombstone_event_id = room
        .set_tombstone(body.to_owned(), replacement_room_id.clone())
        .await?;

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
        tombstone_event_id,
        "event id should match"
    );
    assert_eq!(activity.sender_id_str(), admin.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id.to_string());
    assert_eq!(activity.room_id_str(), room_id.to_string());
    assert_eq!(activity.type_str(), "roomTombstone");
    assert_eq!(
        activity.origin_server_ts(),
        Into::<u64>::into(meta.origin_server_ts.get())
    );

    // check the content of activity
    let content = activity.room_tombstone_content()?;

    assert_eq!(
        content.body_change(),
        Some("Set".to_owned()),
        "body in room tombstone should be set"
    );
    assert_eq!(
        content.body_new_val(),
        body,
        "new val of body in room tombstone is invalid"
    );

    assert_eq!(
        content.replacement_room_change(),
        Some("Set".to_owned()),
        "replacement in room tombstone should be set"
    );
    assert_eq!(
        content.replacement_room_new_val(),
        replacement_room_id.as_str(),
        "new val of replacement in room tombstone is invalid"
    );

    Ok(())
}

fn gen_id(len: usize) -> String {
    let alphabet: [char; 16] = [
        '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', 'a', 'b', 'c', 'd', 'e', 'f',
    ];
    return nanoid!(len, &alphabet);
}
