use acter_core::{activities::Activity, models::status::membership::MembershipChange};
use anyhow::{bail, Result};
use matrix_sdk::ruma::OwnedRoomId;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use acter::{Client, SyncState};

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
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        _setup_accounts("ij-status-notif").await?;
    let mut third = random_user("mickey").await?;
    let to_invite_user_name = third.user_id()?;
    let _third_state = third.start_sync();

    let admin_room = admin.room(room_id.to_string()).await?;
    let observer_room_activities = observer.activities_for_room(room_id.to_string())?;
    let mut obs_observer = observer_room_activities.subscribe();

    // ensure it was sent
    assert!(
        admin_room
            .invite_user(to_invite_user_name.to_string())
            .await?
    );

    obs_observer.recv().await?; // await for it have been coming in

    // wait for the event to come in
    let obs = observer.clone();
    let room_activities = observer_room_activities.clone();
    let activity = Retry::spawn(retry_strategy.clone(), move || {
        let room_activities = room_activities.clone();
        let ob = obs.clone();
        async move {
            let m = room_activities.get_ids(0, 1).await?;
            let Some(id) = m.first().cloned() else {
                bail!("no latest room activity found");
            };
            ob.activity(id).await
        }
    })
    .await?;

    let Activity::MembershipChange(_, r) = activity.inner();

    assert!(matches!(r, MembershipChange::Invited));
    assert_eq!(r.as_str(), "invited");

    // let the third accept the invite

    let third = third.clone();
    let invited_room = Retry::spawn(retry_strategy.clone(), move || {
        let third = third.clone();

        async move {
            let Some(room) = third.invited_rooms().first().cloned() else {
                bail!("No invite found");
            };
            Ok(room)
        }
    })
    .await?;

    invited_room.join().await?;

    obs_observer.recv().await?; // await for it have been coming in

    // wait for the event to come in
    let obs = observer.clone();
    let room_activities = observer_room_activities.clone();
    let activity = Retry::spawn(retry_strategy.clone(), move || {
        let room_activities = room_activities.clone();
        let ob = obs.clone();
        async move {
            let m = room_activities.get_ids(0, 1).await?;
            let Some(id) = m.first().cloned() else {
                bail!("no latest room activity found");
            };
            ob.activity(id).await
        }
    })
    .await?;

    let Activity::MembershipChange(_, r) = activity.inner();

    assert!(matches!(r, MembershipChange::InvitationAccepted));
    assert_eq!(r.as_str(), "invitationAccepted");

    Ok(())
}

#[tokio::test]
async fn kicked() -> Result<()> {
    let _ = env_logger::try_init();
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        _setup_accounts("ij-status-notif").await?;

    let admin_room = admin.room(room_id.to_string()).await?;
    let room_activities = admin.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    // ensure it was sent
    admin_room.kick_user(&observer.user_id()?, None).await?;

    activities_listenerd.recv().await?; // await for it have been coming in

    // wait for the event to come in
    let cl = admin.clone();
    let room_activities = room_activities.clone();
    let activity = Retry::spawn(retry_strategy.clone(), move || {
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

    let Activity::MembershipChange(_, r) = activity.inner();

    assert!(matches!(r, MembershipChange::Kicked));
    assert_eq!(r.as_str(), "kicked");
    Ok(())
}

#[tokio::test]
async fn invite_and_rejected() -> Result<()> {
    let _ = env_logger::try_init();
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        _setup_accounts("ij-status-notif").await?;
    let mut third = random_user("mickey").await?;
    let to_invite_user_name = third.user_id()?;
    let _third_state = third.start_sync();

    let admin_room = admin.room(room_id.to_string()).await?;
    let observer_room_activities = observer.activities_for_room(room_id.to_string())?;
    let mut obs_observer = observer_room_activities.subscribe();

    // ensure it was sent
    assert!(
        admin_room
            .invite_user(to_invite_user_name.to_string())
            .await?
    );

    obs_observer.recv().await?; // await for it have been coming in

    // wait for the event to come in
    let obs = observer.clone();
    let room_activities = observer_room_activities.clone();
    let activity = Retry::spawn(retry_strategy.clone(), move || {
        let room_activities = room_activities.clone();
        let ob = obs.clone();
        async move {
            let m = room_activities.get_ids(0, 1).await?;
            let Some(id) = m.first().cloned() else {
                bail!("no latest room activity found");
            };
            ob.activity(id).await
        }
    })
    .await?;

    let Activity::MembershipChange(_, r) = activity.inner();

    assert!(matches!(r, MembershipChange::Invited));
    assert_eq!(r.as_str(), "invited");

    // let the third accept the invite

    let third = third.clone();
    let invited_room = Retry::spawn(retry_strategy.clone(), move || {
        let third = third.clone();

        async move {
            let Some(room) = third.invited_rooms().first().cloned() else {
                bail!("No invite found");
            };
            Ok(room)
        }
    })
    .await?;

    invited_room.leave().await?;

    obs_observer.recv().await?; // await for it have been coming in

    // wait for the event to come in
    let obs = observer.clone();
    let room_activities = observer_room_activities.clone();
    let activity = Retry::spawn(retry_strategy.clone(), move || {
        let room_activities = room_activities.clone();
        let ob = obs.clone();
        async move {
            let m = room_activities.get_ids(0, 1).await?;
            let Some(id) = m.first().cloned() else {
                bail!("no latest room activity found");
            };
            ob.activity(id).await
        }
    })
    .await?;

    let Activity::MembershipChange(_, r) = activity.inner();

    assert!(matches!(r, MembershipChange::InvitationRejected));
    assert_eq!(r.as_str(), "invitationRejected");

    Ok(())
}

#[tokio::test]
async fn kickban_and_unban() -> Result<()> {
    let _ = env_logger::try_init();
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        _setup_accounts("ij-status-notif").await?;

    let admin_room = admin.room(room_id.to_string()).await?;
    let main_room_activities = admin.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = main_room_activities.subscribe();

    // ensure it was sent
    admin_room.ban_user(&observer.user_id()?, None).await?;

    activities_listenerd.recv().await?; // await for it have been coming in

    // wait for the event to come in
    let cl = admin.clone();
    let room_activities = main_room_activities.clone();
    let activity = Retry::spawn(retry_strategy.clone(), move || {
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

    let Activity::MembershipChange(_, r) = activity.inner();

    assert!(matches!(r, MembershipChange::KickedAndBanned));
    assert_eq!(r.as_str(), "kickedAndBanned");

    // ensure it was sent
    admin_room.unban_user(&observer.user_id()?, None).await?;

    activities_listenerd.recv().await?; // await for it have been coming in

    // wait for the event to come in
    let cl = admin.clone();
    let room_activities = main_room_activities.clone();
    let activity = Retry::spawn(retry_strategy.clone(), move || {
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

    let Activity::MembershipChange(_, r) = activity.inner();

    assert!(matches!(r, MembershipChange::Unbanned));
    assert_eq!(r.as_str(), "unbanned");
    Ok(())
}

#[tokio::test]
async fn left() -> Result<()> {
    let _ = env_logger::try_init();
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        _setup_accounts("ij-status-notif").await?;

    let room = observer.room(room_id.to_string()).await?;
    let room_activities = admin.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    // ensure it was sent
    room.leave().await?;

    activities_listenerd.recv().await?; // await for it have been coming in

    // wait for the event to come in
    let cl = admin.clone();
    let room_activities = room_activities.clone();
    let activity = Retry::spawn(retry_strategy.clone(), move || {
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

    let Activity::MembershipChange(_, r) = activity.inner();

    assert!(matches!(r, MembershipChange::Left));
    assert_eq!(r.as_str(), "left");
    Ok(())
}
