use acter_core::activities::ActivityContent;
use anyhow::{bail, Result};
use matrix_sdk_base::ruma::events::room::guest_access::GuestAccess;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};
use tracing::info;

use super::setup_accounts;

#[tokio::test]
#[ignore = "test doesn't receive m.room.guest_access event on activity :("]
async fn test_room_guest_access() -> Result<()> {
    let _ = env_logger::try_init();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("room-guest-access").await?;

    let room = admin.room(room_id.to_string()).await?;
    let room_activities = observer.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    info!("1111111111111111111111111111111111111111");

    // ensure it was sent
    let guest_access = GuestAccess::CanJoin;
    let access_event_id = room.set_guest_access(guest_access.to_string()).await?;

    info!("222222222222222222222222222222222222222");

    activities_listenerd.recv().await?; // await for it have been coming in

    info!("333333333333333333333333333333333333333");

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

    info!("44444444444444444444444444444444444444");

    // external API check
    let meta = activity.event_meta();
    assert_eq!(
        meta.event_id.clone(),
        access_event_id,
        "event id should match"
    );
    assert_eq!(activity.sender_id_str(), admin.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id.to_string());
    assert_eq!(activity.room_id_str(), room_id.to_string());
    assert_eq!(activity.type_str(), "roomGuestAccess");
    assert_eq!(
        activity.origin_server_ts(),
        Into::<u64>::into(meta.origin_server_ts.get())
    );

    // check the content of activity
    let content = activity.room_guest_access_content()?;

    assert_eq!(
        content.change(),
        Some("Set".to_owned()),
        "room guest access should be set"
    );
    assert_eq!(
        content.new_val(),
        guest_access.to_string(),
        "new val of room guest access is invalid"
    );
    assert_eq!(
        content.old_val(),
        None,
        "old val of room guest access is invalid"
    );

    Ok(())
}
