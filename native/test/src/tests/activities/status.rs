use anyhow::{bail, Result};
use std::io::Write;
use tempfile::Builder;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use super::{get_latest_activity, setup_accounts};
use crate::{
    tests::activities::{all_activities_observer, assert_triggered_with_latest_activity},
    utils::random_user,
};

#[tokio::test]
async fn initial_events() -> Result<()> {
    let _ = env_logger::try_init();
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("initial-events").await?;
    // ensure the roomName works on both
    let activity = get_latest_activity(&admin, room_id.to_string(), "roomName").await?;
    assert_eq!(activity.type_str(), "roomName");

    let activity = get_latest_activity(&observer, room_id.to_string(), "roomName").await?;
    assert_eq!(activity.type_str(), "roomName");
    // // check the create event
    // let room_activities = observer_room_activities.clone();
    // let created = Retry::spawn(retry_strategy, move || {
    //     let room_activities = room_activities.clone();
    //     async move {
    //         let Some(a) = room_activities
    //             .iter()
    //             .await?
    //             .find(|f| f.type_str() == "roomCreated")
    //         else {
    //             bail!("no create activity found")
    //         };
    //         Ok(a)
    //     }
    // })
    // .await?;
    // assert_eq!(created.type_str(), "created");

    // let Some(r) = activity.membership_content() else {
    //     bail!("not a membership event");
    // };
    // assert!(matches!(r.change, MembershipChangeType::Invited));
    // assert_eq!(r.as_str(), "invited");
    // assert_eq!(r.user_id, to_invite_user_name);

    Ok(())
}

#[tokio::test]
async fn invite_and_join() -> Result<()> {
    let _ = env_logger::try_init();
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("invite-and-join").await?;
    let mut third = random_user("mickey").await?;
    let to_invite_user_name = third.user_id()?;
    let _third_state = third.start_sync();
    let mut act_obs = all_activities_observer(&observer).await?;
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

    let Some(r) = activity.membership_content() else {
        bail!("not a membership event");
    };

    assert_eq!(r.change(), "invited");
    assert_eq!(r.user_id(), to_invite_user_name);
    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;
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
    let activity = Retry::spawn(retry_strategy, move || {
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

    let Some(r) = activity.membership_content() else {
        bail!("not a membership event");
    };
    let meta = activity.event_meta();

    assert_eq!(r.change(), "invitationAccepted");
    assert_eq!(r.user_id(), to_invite_user_name);
    assert_eq!(meta.sender, r.user_id());
    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;
    Ok(())
}

#[tokio::test]
async fn kicked() -> Result<()> {
    let _ = env_logger::try_init();
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) = setup_accounts("kicked").await?;
    let mut act_obs = all_activities_observer(&admin).await?;
    let admin_room = admin.room(room_id.to_string()).await?;
    let room_activities = admin.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    // ensure it was sent
    admin_room.kick_user(&observer.user_id()?, None).await?;

    activities_listenerd.recv().await?; // await for it have been coming in

    // wait for the event to come in
    let cl = admin.clone();
    let room_activities = room_activities.clone();
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

    let Some(r) = activity.membership_content() else {
        bail!("not a membership event");
    };
    let meta = activity.event_meta();

    assert_eq!(r.change(), "kicked");
    assert_eq!(r.user_id(), observer.user_id()?);
    assert_eq!(meta.sender, admin.user_id()?);
    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;
    Ok(())
}

#[tokio::test]
async fn invite_and_rejected() -> Result<()> {
    let _ = env_logger::try_init();
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("invite-and-rejected").await?;
    let mut third = random_user("mickey").await?;
    let to_invite_user_name = third.user_id()?;
    let _third_state = third.start_sync();
    let mut act_obs = all_activities_observer(&observer).await?;
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

    let Some(r) = activity.membership_content() else {
        bail!("not a membership event");
    };
    let meta = activity.event_meta();

    assert_eq!(r.change(), "invited");
    assert_eq!(r.user_id(), to_invite_user_name);
    assert_eq!(meta.sender, admin.user_id()?);
    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;
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
    let activity = Retry::spawn(retry_strategy, move || {
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

    let Some(r) = activity.membership_content() else {
        bail!("not a membership event");
    };
    let meta = activity.event_meta();

    assert_eq!(r.change(), "invitationRejected");
    assert_eq!(r.user_id(), to_invite_user_name);
    assert_eq!(meta.sender, r.user_id());
    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;
    Ok(())
}

#[tokio::test]
async fn kickban_and_unban() -> Result<()> {
    let _ = env_logger::try_init();
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("kickban-and-unban").await?;

    let admin_room = admin.room(room_id.to_string()).await?;
    let main_room_activities = admin.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = main_room_activities.subscribe();
    let mut act_obs = all_activities_observer(&admin).await?;
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

    let Some(r) = activity.membership_content() else {
        bail!("not a membership event");
    };
    let meta = activity.event_meta();

    assert_eq!(r.change(), "kickedAndBanned");
    assert_eq!(r.user_id(), observer.user_id()?);
    assert_eq!(meta.sender, admin.user_id()?);
    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;
    // ensure it was sent
    admin_room.unban_user(&observer.user_id()?, None).await?;

    activities_listenerd.recv().await?; // await for it have been coming in

    // wait for the event to come in
    let cl = admin.clone();
    let room_activities = main_room_activities.clone();
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

    let Some(r) = activity.membership_content() else {
        bail!("not a membership event");
    };
    let meta = activity.event_meta();

    assert_eq!(r.change(), "unbanned");
    assert_eq!(r.user_id(), observer.user_id()?);
    assert_eq!(meta.sender, admin.user_id()?);
    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;
    Ok(())
}

#[tokio::test]
async fn left() -> Result<()> {
    let _ = env_logger::try_init();
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) = setup_accounts("left").await?;

    let room = observer.room(room_id.to_string()).await?;
    let room_activities = admin.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();
    let mut act_obs = all_activities_observer(&admin).await?;
    // ensure it was sent
    room.leave().await?;

    activities_listenerd.recv().await?; // await for it have been coming in

    // wait for the event to come in
    let cl = admin.clone();
    let room_activities = room_activities.clone();
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

    let Some(r) = activity.membership_content() else {
        bail!("not a membership event");
    };
    let meta = activity.event_meta();

    assert_eq!(r.change(), "left");
    assert_eq!(r.user_id(), observer.user_id()?);
    assert_eq!(meta.sender, observer.user_id()?);

    // external API check
    assert_eq!(activity.sender_id_str(), observer.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id);
    assert_eq!(activity.room_id_str(), room.room_id_str());
    assert_eq!(activity.type_str(), "left");
    assert_eq!(
        activity.origin_server_ts(),
        Into::<u64>::into(meta.origin_server_ts.get())
    );
    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;
    Ok(())
}

#[tokio::test]
async fn display_name() -> Result<()> {
    let _ = env_logger::try_init();
    let ((admin, _handle1), (observer, _handle2), room_id) = setup_accounts("display-name").await?;
    let mut act_obs = all_activities_observer(&observer).await?;
    // ensure it was sent
    let account = observer.account()?;
    account.set_display_name("Mickey Mouse".to_owned()).await?;

    // wait for the event to come in
    let activity = get_latest_activity(&admin, room_id.to_string(), "displayName").await?;

    assert_eq!(activity.type_str(), "displayName");
    let Some(r) = activity.profile_content() else {
        bail!("not a profile event");
    };
    let meta = activity.event_meta();

    assert_eq!(r.display_name_new_val().as_deref(), Some("Mickey Mouse"));
    assert_eq!(meta.sender, observer.user_id()?);

    // external API check
    assert_eq!(activity.sender_id_str(), observer.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id);
    assert_eq!(activity.room_id_str(), room_id);
    assert_eq!(
        activity.origin_server_ts(),
        Into::<u64>::into(meta.origin_server_ts.get())
    );
    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;
    Ok(())
}

#[tokio::test]
async fn avatar_url() -> Result<()> {
    let _ = env_logger::try_init();
    let ((admin, _handle1), (observer, _handle2), room_id) = setup_accounts("avatar-url").await?;
    let mut act_obs = all_activities_observer(&observer).await?;
    let bytes = include_bytes!("../fixtures/kingfisher.jpg");
    let mut tmp_jpg = Builder::new().suffix(".jpg").tempfile()?;
    tmp_jpg.as_file_mut().write_all(bytes)?;
    let jpg_path = tmp_jpg // it is randomly generated by system and not kingfisher.jpg
        .path()
        .to_string_lossy()
        .to_string();

    // ensure it was sent
    let account = observer.account()?;
    let uri = account.upload_avatar(jpg_path).await?;

    // wait for the event to come in
    let activity = get_latest_activity(&admin, room_id.to_string(), "avatarUrl").await?;

    assert_eq!(activity.type_str(), "avatarUrl");
    let Some(r) = activity.profile_content() else {
        bail!("not a profile event");
    };
    let meta = activity.event_meta();

    assert_eq!(r.avatar_url_new_val(), Some(uri));
    assert_eq!(meta.sender, observer.user_id()?);

    // external API check
    assert_eq!(activity.sender_id_str(), observer.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id);
    assert_eq!(activity.room_id_str(), room_id);
    assert_eq!(
        activity.origin_server_ts(),
        Into::<u64>::into(meta.origin_server_ts.get())
    );
    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;
    Ok(())
}
