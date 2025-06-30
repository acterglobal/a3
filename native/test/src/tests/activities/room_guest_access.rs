use anyhow::Result;
use matrix_sdk_base::ruma::events::room::guest_access::GuestAccess;

use super::{get_latest_activity, setup_accounts};

#[tokio::test]
async fn test_room_guest_access() -> Result<()> {
    let _ = env_logger::try_init();

    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("room-guest-access").await?;
    let room = admin.room(room_id.to_string()).await?;

    // ensure it was sent
    let guest_access = GuestAccess::CanJoin;
    let access_event_id = room.set_guest_access(guest_access.to_string()).await?;

    // wait for the event to come in
    let activity = get_latest_activity(&observer, room_id.to_string(), "roomGuestAccess").await?;

    // external API check
    let meta = activity.event_meta();
    assert_eq!(
        meta.event_id.clone(),
        access_event_id,
        "event id should match"
    );
    assert_eq!(activity.sender_id_str(), admin.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id);
    assert_eq!(activity.room_id_str(), room_id);
    assert_eq!(activity.type_str(), "roomGuestAccess");
    let ts: u64 = meta.origin_server_ts.get().into();
    assert_eq!(activity.origin_server_ts(), ts);

    // check the content of activity
    let content = activity
        .room_guest_access_content()
        .expect("not a room guest access event");

    assert_eq!(
        content.change().as_deref(),
        Some("Set"),
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
