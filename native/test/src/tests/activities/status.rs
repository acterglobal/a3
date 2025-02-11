use acter_core::activities::Activity;
use anyhow::{bail, Result};
use matrix_sdk::ruma::OwnedRoomId;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use acter::{
    matrix_sdk_ui::timeline::{MembershipChange, RoomExt, TimelineItemContent},
    Client, SyncState,
};

use crate::utils::{random_user, random_users_with_random_space};

async fn _setup_accounts(
    prefix: &str,
) -> Result<((Client, SyncState), (Client, SyncState), OwnedRoomId)> {
    let (users, room_id) = random_users_with_random_space(prefix, 2).await?;
    let mut admin = users[0].clone();
    let mut observer = users[1].clone();

    observer.install_default_acter_push_rules().await?;

    let sync_state1 = admin.start_sync();
    sync_state1.await_has_synced_history().await?;

    let sync_state2 = observer.start_sync();
    sync_state2.await_has_synced_history().await?;

    Ok(((admin, sync_state1), (observer, sync_state2), room_id))
}

#[tokio::test]
async fn invite_and_join() -> Result<()> {
    let _ = env_logger::try_init();
    let ((admin, _handle1), (observer, _handle2), room_id) =
        _setup_accounts("ij-status-notif").await?;
    let third = random_user("mickey").await?;
    let to_invite_user_name = third.user_id()?;

    let admin_room = admin.room(room_id.to_string()).await?;
    let timeline = admin_room.timeline().await?;

    // ensure it was sent
    assert!(
        admin_room
            .invite_user(to_invite_user_name.to_string())
            .await?
    );

    // fetch the items
    timeline.paginate_backwards(5).await?;

    // find the event id for the invite
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let r = admin_room.clone();
    let u = to_invite_user_name.clone();
    let notif_id = Retry::spawn(retry_strategy.clone(), move || {
        let r = r.clone();
        let u = u.clone();
        async move {
            let Some(e) = r.timeline().await?.latest_event().await else {
                bail!("No event found")
            };
            let TimelineItemContent::MembershipChange(c) = e.content() else {
                bail!("latest is not membership change");
            };

            let Some(MembershipChange::Invited) = c.change() else {
                bail!("not an invite")
            };

            if c.user_id() != u {
                bail!("Not the latest user");
            }

            Ok(e.event_id().expect("it has an event_id").to_owned())
        }
    })
    .await?;

    let obs = observer.clone();
    let id = notif_id.to_string();
    let activity = Retry::spawn(retry_strategy.clone(), || {
        let ob = obs.clone();
        let id = id.clone();
        async move { ob.activity(id).await }
    })
    .await?;

    assert!(matches!(activity.inner(), Activity::MemberInvited(_)));

    // assert_eq!(
    //     notification_item
    //         .parent_id_str()
    //         .expect("parent is in like"),
    //     news_entry.event_id().to_string()
    // );
    // assert!(notification_item.body().is_none());
    // assert_eq!(notification_item.reaction_key(), Some("❤️".to_owned()));
    // let parent = notification_item.parent().expect("parent was found");
    // assert_eq!(parent.title(), None);
    // assert_eq!(parent.emoji(), "🚀"); // rocket
    // assert_eq!(parent.object_id_str(), news_entry.event_id().to_string());

    Ok(())
}
