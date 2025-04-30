use anyhow::{bail, Result};
use matrix_sdk_base::ruma::EventEncryptionAlgorithm;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use super::setup_accounts;

#[tokio::test]
async fn test_room_encryption() -> Result<()> {
    let _ = env_logger::try_init();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("room-encryption").await?;

    let room = admin.room(room_id.to_string()).await?;
    let room_activities = observer.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    // ensure it was sent
    let new_algorithm = EventEncryptionAlgorithm::OlmV1Curve25519AesSha2;
    let encryption_event_id = room.set_encryption(new_algorithm.to_string()).await?;

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
        encryption_event_id,
        "event id should match"
    );
    assert_eq!(activity.sender_id_str(), admin.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id.to_string());
    assert_eq!(activity.room_id_str(), room.room_id_str());
    assert_eq!(activity.type_str(), "roomEncryption");
    assert_eq!(
        activity.origin_server_ts(),
        Into::<u64>::into(meta.origin_server_ts.get())
    );

    // check the content of activity
    let content = activity
        .room_encryption_content()
        .expect("not a room encryption event");

    assert_eq!(
        content.algorithm_change(),
        Some("Set".to_owned()),
        "algorithm in room encryption should be set"
    );
    assert_eq!(
        content.algorithm_new_val(),
        new_algorithm.to_string(),
        "new val of algorithm in room encryption is invalid"
    );
    assert_eq!(
        content.algorithm_old_val(),
        None,
        "old val of algorithm in room encryption is invalid"
    );

    Ok(())
}
