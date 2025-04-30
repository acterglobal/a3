use acter_core::activities::ActivityContent;
use anyhow::{bail, Result};
use matrix_sdk_base::ruma::events::TimelineEventType;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use super::setup_accounts;

#[tokio::test]
async fn test_room_power_levels_ban() -> Result<()> {
    let _ = env_logger::try_init();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("room-power-levels-ban").await?;

    let room = admin.room(room_id.to_string()).await?;
    let room_activities = observer.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    // ensure it was sent
    let new_level: i64 = 100;
    let default_level = 50;
    let ban_event_id = room.set_power_levels_ban(new_level as i32).await?;

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
    assert_eq!(meta.event_id.clone(), ban_event_id, "event id should match");
    assert_eq!(activity.sender_id_str(), admin.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id.to_string());
    assert_eq!(activity.room_id_str(), room_id.to_string());
    assert_eq!(activity.type_str(), "roomPowerLevels");
    assert_eq!(
        activity.origin_server_ts(),
        Into::<u64>::into(meta.origin_server_ts.get())
    );

    // check the content of activity
    let content = activity
        .room_power_levels_content()
        .expect("not a room power levels event");

    assert_eq!(
        content.ban_change(),
        Some("Changed".to_owned()),
        "room power levels should be changed"
    );
    assert_eq!(
        content.ban_new_val(),
        new_level,
        "new val of room power levels is invalid"
    );
    assert_eq!(
        content.ban_old_val(),
        Some(default_level),
        "old val of room power levels is invalid"
    );

    Ok(())
}

#[tokio::test]
async fn test_room_power_levels_events() -> Result<()> {
    let _ = env_logger::try_init();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("room-power-levels-events").await?;

    let room = admin.room(room_id.to_string()).await?;
    let room_activities = observer.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    // ensure it was sent
    let event_type = TimelineEventType::RoomAvatar;
    let new_level: i64 = 100;
    let level_event_id = room
        .set_power_levels_events(event_type.to_string(), new_level as i32)
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
        level_event_id,
        "event id should match"
    );

    assert_eq!(activity.sender_id_str(), admin.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id.to_string());
    assert_eq!(activity.room_id_str(), room_id.to_string());
    assert_eq!(activity.type_str(), "roomPowerLevels");
    assert_eq!(
        activity.origin_server_ts(),
        Into::<u64>::into(meta.origin_server_ts.get())
    );

    // check the content of activity
    let content = activity
        .room_power_levels_content()
        .expect("not a room power levels event");

    assert_eq!(
        content.events_change(event_type.to_string()),
        Some("Set".to_owned()),
        "room power levels should be set"
    );
    assert_eq!(
        content.events_new_val(event_type.to_string()),
        Some(new_level),
        "new val of room power levels is invalid"
    );
    assert_eq!(
        content.events_old_val(event_type.to_string()),
        None,
        "old val of room power levels is invalid"
    );

    Ok(())
}

#[tokio::test]
async fn test_room_power_levels_events_default() -> Result<()> {
    let _ = env_logger::try_init();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("room-power-levels-events-default").await?;

    let room = admin.room(room_id.to_string()).await?;
    let room_activities = observer.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    // ensure it was sent
    let new_level: i64 = 50;
    let default_level = 0;
    let default_event_id = room
        .set_power_levels_events_default(new_level as i32)
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
        default_event_id,
        "event id should match"
    );
    assert_eq!(activity.sender_id_str(), admin.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id.to_string());
    assert_eq!(activity.room_id_str(), room_id.to_string());
    assert_eq!(activity.type_str(), "roomPowerLevels");
    assert_eq!(
        activity.origin_server_ts(),
        Into::<u64>::into(meta.origin_server_ts.get())
    );

    // check the content of activity
    let content = activity
        .room_power_levels_content()
        .expect("not a room power levels event");

    assert_eq!(
        content.events_default_change(),
        Some("Changed".to_owned()),
        "room power levels should be changed"
    );
    assert_eq!(
        content.events_default_new_val(),
        new_level,
        "new val of room power levels is invalid"
    );
    assert_eq!(
        content.events_default_old_val(),
        Some(default_level),
        "old val of room power levels is invalid"
    );

    Ok(())
}

#[tokio::test]
async fn test_room_power_levels_invite() -> Result<()> {
    let _ = env_logger::try_init();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("room-power-levels-invite").await?;

    let room = admin.room(room_id.to_string()).await?;
    let room_activities = observer.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    // ensure it was sent
    let new_level: i64 = 50;
    let default_level = 0;
    let invite_event_id = room.set_power_levels_invite(new_level as i32).await?;

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
        invite_event_id,
        "event id should match"
    );
    assert_eq!(activity.sender_id_str(), admin.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id.to_string());
    assert_eq!(activity.room_id_str(), room_id.to_string());
    assert_eq!(activity.type_str(), "roomPowerLevels");
    assert_eq!(
        activity.origin_server_ts(),
        Into::<u64>::into(meta.origin_server_ts.get())
    );

    // check the content of activity
    let content = activity
        .room_power_levels_content()
        .expect("not a room power levels event");

    assert_eq!(
        content.invite_change(),
        Some("Changed".to_owned()),
        "room power levels should be changed"
    );
    assert_eq!(
        content.invite_new_val(),
        new_level,
        "new val of room power levels is invalid"
    );
    assert_eq!(
        content.invite_old_val(),
        Some(default_level),
        "old val of room power levels is invalid"
    );

    Ok(())
}

#[tokio::test]
async fn test_room_power_levels_kick() -> Result<()> {
    let _ = env_logger::try_init();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("room-power-levels-kick").await?;

    let room = admin.room(room_id.to_string()).await?;
    let room_activities = observer.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    // ensure it was sent
    let new_level: i64 = 100;
    let default_level = 50;
    let kick_event_id = room.set_power_levels_kick(new_level as i32).await?;

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
        kick_event_id,
        "event id should match"
    );
    assert_eq!(activity.sender_id_str(), admin.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id.to_string());
    assert_eq!(activity.room_id_str(), room_id.to_string());
    assert_eq!(activity.type_str(), "roomPowerLevels");
    assert_eq!(
        activity.origin_server_ts(),
        Into::<u64>::into(meta.origin_server_ts.get())
    );

    // check the content of activity
    let content = activity
        .room_power_levels_content()
        .expect("not a room power levels event");

    assert_eq!(
        content.kick_change(),
        Some("Changed".to_owned()),
        "room power levels should be changed"
    );
    assert_eq!(
        content.kick_new_val(),
        new_level,
        "new val of room power levels is invalid"
    );
    assert_eq!(
        content.kick_old_val(),
        Some(default_level),
        "old val of room power levels is invalid"
    );

    Ok(())
}

#[tokio::test]
async fn test_room_power_levels_redact() -> Result<()> {
    let _ = env_logger::try_init();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("room-power-levels-redact").await?;

    let room = admin.room(room_id.to_string()).await?;
    let room_activities = observer.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    // ensure it was sent
    let new_level: i64 = 100;
    let default_level = 50;
    let redact_event_id = room.set_power_levels_redact(new_level as i32).await?;

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
        redact_event_id,
        "event id should match"
    );
    assert_eq!(activity.sender_id_str(), admin.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id.to_string());
    assert_eq!(activity.room_id_str(), room_id.to_string());
    assert_eq!(activity.type_str(), "roomPowerLevels");
    assert_eq!(
        activity.origin_server_ts(),
        Into::<u64>::into(meta.origin_server_ts.get())
    );

    // check the content of activity
    let content = activity
        .room_power_levels_content()
        .expect("not a room power levels event");

    assert_eq!(
        content.redact_change(),
        Some("Changed".to_owned()),
        "room power levels should be changed"
    );
    assert_eq!(
        content.redact_new_val(),
        new_level,
        "new val of room power levels is invalid"
    );
    assert_eq!(
        content.redact_old_val(),
        Some(default_level),
        "old val of room power levels is invalid"
    );

    Ok(())
}

#[tokio::test]
async fn test_room_power_levels_state_default() -> Result<()> {
    let _ = env_logger::try_init();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("room-power-levels-state-default").await?;

    let room = admin.room(room_id.to_string()).await?;
    let room_activities = observer.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    // ensure it was sent
    let new_level: i64 = 100;
    let default_level = 50;
    let default_event_id = room
        .set_power_levels_state_default(new_level as i32)
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
        default_event_id,
        "event id should match"
    );
    assert_eq!(activity.sender_id_str(), admin.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id.to_string());
    assert_eq!(activity.room_id_str(), room_id.to_string());
    assert_eq!(activity.type_str(), "roomPowerLevels");
    assert_eq!(
        activity.origin_server_ts(),
        Into::<u64>::into(meta.origin_server_ts.get())
    );

    // check the content of activity
    let content = activity
        .room_power_levels_content()
        .expect("not a room power levels event");

    assert_eq!(
        content.state_default_change(),
        Some("Changed".to_owned()),
        "room power levels should be changed"
    );
    assert_eq!(
        content.state_default_new_val(),
        new_level,
        "new val of room power levels is invalid"
    );
    assert_eq!(
        content.state_default_old_val(),
        Some(default_level),
        "old val of room power levels is invalid"
    );

    Ok(())
}

#[tokio::test]
async fn test_room_power_levels_users_default() -> Result<()> {
    let _ = env_logger::try_init();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("room-power-levels-users-default").await?;

    let room = admin.room(room_id.to_string()).await?;
    let room_activities = observer.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    // ensure it was sent
    let new_level: i64 = 50;
    let default_level = 0;
    let default_event_id = room
        .set_power_levels_users_default(new_level as i32)
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
        default_event_id,
        "event id should match"
    );
    assert_eq!(activity.sender_id_str(), admin.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id.to_string());
    assert_eq!(activity.room_id_str(), room_id.to_string());
    assert_eq!(activity.type_str(), "roomPowerLevels");
    assert_eq!(
        activity.origin_server_ts(),
        Into::<u64>::into(meta.origin_server_ts.get())
    );

    // check the content of activity
    let content = activity
        .room_power_levels_content()
        .expect("not a room power levels event");

    assert_eq!(
        content.users_default_change(),
        Some("Changed".to_owned()),
        "room power levels should be changed"
    );
    assert_eq!(
        content.users_default_new_val(),
        new_level,
        "new val of room power levels is invalid"
    );
    assert_eq!(
        content.users_default_old_val(),
        Some(default_level),
        "old val of room power levels is invalid"
    );

    Ok(())
}

#[tokio::test]
async fn test_room_power_levels_notifications() -> Result<()> {
    let _ = env_logger::try_init();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("room-power-levels-notifications").await?;

    let room = admin.room(room_id.to_string()).await?;
    let room_activities = observer.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    // ensure it was sent
    let new_level: i64 = 100;
    let default_level = 50;
    let notifications_event_id = room
        .set_power_levels_notifications(new_level as i32)
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
        notifications_event_id,
        "event id should match"
    );
    assert_eq!(activity.sender_id_str(), admin.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id.to_string());
    assert_eq!(activity.room_id_str(), room_id.to_string());
    assert_eq!(activity.type_str(), "roomPowerLevels");
    assert_eq!(
        activity.origin_server_ts(),
        Into::<u64>::into(meta.origin_server_ts.get())
    );

    // check the content of activity
    let content = activity
        .room_power_levels_content()
        .expect("not a room power levels event");

    assert_eq!(
        content.notifications_change(),
        Some("Changed".to_owned()),
        "room power levels should be changed"
    );
    assert_eq!(
        content.notifications_new_val(),
        new_level,
        "new val of room power levels is invalid"
    );
    assert_eq!(
        content.notifications_old_val(),
        Some(default_level),
        "old val of room power levels is invalid"
    );

    Ok(())
}
