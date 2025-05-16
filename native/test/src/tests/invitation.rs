use acter::matrix_sdk_ui::timeline::{MsgLikeContent, MsgLikeKind, RoomExt, TimelineItemContent};
use anyhow::{bail, Result};
use futures::{FutureExt, StreamExt};
use matrix_sdk::{ruma::events::room::message::RoomMessageEventContent, RoomState};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::{
    invite_user, random_user, random_user_with_random_convo, random_user_with_random_space,
};

#[tokio::test]
async fn chat_invitation_shows_up() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut sisko, room_id) = random_user_with_random_convo("cI").await?;
    let _sisko_syncer = sisko.start_sync();

    let mut kyra = random_user("cI").await?;
    let _kyra_syncer = kyra.start_sync();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);

    let convo = Retry::spawn(retry_strategy.clone(), || async {
        sisko.convo(room_id.to_string()).await
    })
    .await?;

    let invites = kyra.invitations();
    let stream = invites.subscribe_stream();
    let mut stream = stream.fuse();

    convo.invite_user_by_id(&kyra.user_id()?).await?;

    let invited = Retry::spawn(retry_strategy.clone(), || async {
        let invited = kyra.invitations().room_invitations().await?;
        if invited.is_empty() {
            Err(anyhow::anyhow!("No pending invitations found"))
        } else {
            Ok(invited)
        }
    })
    .await?;

    // stream triggered
    assert_eq!(stream.next().await, Some(true));

    assert_eq!(invited.len(), 1);
    let room = invited
        .first()
        .expect("first invitation should be available");
    assert_eq!(room.room_id(), room_id);
    assert_eq!(room.state(), RoomState::Invited);
    assert!(!room.is_space());
    assert_eq!(room.sender_id(), sisko.user_id()?);

    Ok(())
}

#[tokio::test]
async fn space_invitation_shows_up() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut sisko, room_id) = random_user_with_random_space("spI").await?;
    let _sisko_syncer = sisko.start_sync();

    let mut kyra = random_user("spI").await?;
    let _kyra_syncer = kyra.start_sync();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);

    let invites = kyra.invitations();
    let stream = invites.subscribe_stream();
    let mut stream = stream.fuse();

    invite_user(&sisko, &room_id, &kyra.user_id()?).await?;

    let invited = Retry::spawn(retry_strategy.clone(), || async {
        let invited = kyra.invitations().room_invitations().await?;
        if invited.is_empty() {
            Err(anyhow::anyhow!("No pending invitations found"))
        } else {
            Ok(invited)
        }
    })
    .await?;

    // stream triggered
    assert_eq!(stream.next().await, Some(true));

    assert_eq!(invited.len(), 1);
    let room = invited
        .first()
        .expect("first invitation should be available");
    assert_eq!(room.room_id(), room_id);
    assert_eq!(room.state(), RoomState::Invited);
    assert!(room.is_space());
    assert_eq!(room.sender_id(), sisko.user_id()?);

    Ok(())
}

#[tokio::test]
async fn space_invitation_disappears_when_joined() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut sisko, room_id) = random_user_with_random_space("spI").await?;
    let _sisko_syncer = sisko.start_sync();

    let mut kyra = random_user("spI").await?;
    let _kyra_syncer = kyra.start_sync();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);

    let invites = kyra.invitations();
    let stream = invites.subscribe_stream();
    let mut stream = stream.fuse();

    invite_user(&sisko, &room_id, &kyra.user_id()?).await?;

    let manager = invites.clone();

    let invited = Retry::spawn(retry_strategy.clone(), || async {
        let invited = manager.room_invitations().await?;
        if invited.is_empty() {
            Err(anyhow::anyhow!("No pending invitations found"))
        } else {
            Ok(invited)
        }
    })
    .await?;

    // stream triggered
    assert_eq!(stream.next().await, Some(true));

    assert_eq!(invited.len(), 1);
    let room = invited
        .first()
        .expect("first invitation should be available");
    assert_eq!(room.room_id(), room_id);
    assert_eq!(room.state(), RoomState::Invited);
    assert!(room.is_space());
    assert_eq!(room.sender_id(), sisko.user_id()?);

    // second stream

    room.join().await?;
    let manager = invites.clone();

    Retry::spawn(retry_strategy.clone(), || async {
        let invited = manager.room_invitations().await?;
        if !invited.is_empty() {
            Err(anyhow::anyhow!("still pending invitations found"))
        } else {
            Ok(true)
        }
    })
    .await?;

    // we have seen an update on the stream as well
    assert_eq!(stream.next().await, Some(true));

    Ok(())
}

#[tokio::test]
async fn invitations_update_count_when_joined() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut sisko, sisko_room_id) = random_user_with_random_space("spI").await?;
    let (mut worf, worf_room_id) = random_user_with_random_space("sp2").await?;
    let (mut gundom, gundom_room_id) = random_user_with_random_space("sp3").await?;
    let _sisko_syncer = sisko.start_sync();
    let _worf_syncer = worf.start_sync();
    let _gundom_syncer = gundom.start_sync();

    let mut kyra = random_user("spI").await?;
    let _kyra_syncer = kyra.start_sync();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let invites = kyra.invitations();
    let stream = invites.subscribe_stream();
    let mut stream = stream.fuse();

    invite_user(&sisko, &sisko_room_id, &kyra.user_id()?).await?;

    // sisko's invite

    let manager = invites.clone();

    let invited = Retry::spawn(retry_strategy.clone(), || async {
        let invited = manager.room_invitations().await?;
        if invited.is_empty() {
            Err(anyhow::anyhow!("No pending invitations found"))
        } else {
            Ok(invited)
        }
    })
    .await?;

    // stream triggered
    assert_eq!(stream.next().await, Some(true));

    assert_eq!(invited.len(), 1);
    let room = invited
        .first()
        .expect("first invitation should be available");
    assert_eq!(room.room_id(), sisko_room_id);
    assert_eq!(room.state(), RoomState::Invited);
    assert!(room.is_space());
    assert_eq!(room.sender_id(), sisko.user_id()?);

    invite_user(&worf, &worf_room_id, &kyra.user_id()?).await?;
    // and has been seen
    assert_eq!(stream.next().await, Some(true));

    invite_user(&gundom, &gundom_room_id, &kyra.user_id()?).await?;
    // and has been seen
    assert_eq!(stream.next().await, Some(true));

    room.join().await?;
    let manager = invites.clone();

    Retry::spawn(retry_strategy.clone(), || async {
        let invited = manager.room_invitations().await?;
        if invited.len() != 2 {
            Err(anyhow::anyhow!("not yet updated"))
        } else {
            Ok(true)
        }
    })
    .await?;

    // we have seen an update on the stream as well
    assert_eq!(stream.next().await, Some(true));
    // and no further updates
    assert_eq!(stream.next().now_or_never(), None);

    Ok(())
}

#[tokio::test]
async fn no_invite_count_update_on_message() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut sisko, sisko_room_id) = random_user_with_random_space("spI").await?;
    let (mut worf, worf_room_id) = random_user_with_random_space("sp2").await?;
    let (mut gundom, gundom_room_id) = random_user_with_random_space("sp3").await?;
    let _sisko_syncer = sisko.start_sync();
    let _worf_syncer = worf.start_sync();
    let _gundom_syncer = gundom.start_sync();

    let mut kyra = random_user("spI").await?;
    let _kyra_syncer = kyra.start_sync();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let invites = kyra.invitations();
    let stream = invites.subscribe_stream();
    let mut stream = stream.fuse();

    let sisko_room = invite_user(&sisko, &sisko_room_id, &kyra.user_id()?).await?;

    // sisko's invite

    let manager = invites.clone();

    let invited = Retry::spawn(retry_strategy.clone(), || async {
        let invited = manager.room_invitations().await?;
        if invited.is_empty() {
            Err(anyhow::anyhow!("No pending invitations found"))
        } else {
            Ok(invited)
        }
    })
    .await?;

    // stream triggered
    assert_eq!(stream.next().await, Some(true));

    assert_eq!(invited.len(), 1);
    let room = invited
        .first()
        .expect("first invitation should be available");
    assert_eq!(room.room_id(), sisko_room_id);
    assert_eq!(room.state(), RoomState::Invited);
    assert!(room.is_space());
    assert_eq!(room.sender_id(), sisko.user_id()?);

    invite_user(&worf, &worf_room_id, &kyra.user_id()?).await?;
    // and has been seen
    assert_eq!(stream.next().await, Some(true));

    invite_user(&gundom, &gundom_room_id, &kyra.user_id()?).await?;
    // and has been seen
    assert_eq!(stream.next().await, Some(true));

    room.join().await?;
    let manager = invites.clone();

    Retry::spawn(retry_strategy.clone(), || async {
        let invited = manager.room_invitations().await?;
        if invited.len() != 2 {
            Err(anyhow::anyhow!("not yet updated"))
        } else {
            Ok(true)
        }
    })
    .await?;

    // we have seen an update on the stream as well
    assert_eq!(stream.next().await, Some(true));
    // and no further updates
    assert_eq!(stream.next().now_or_never(), None);

    // now let there be something happening in the room
    let room = kyra.room(sisko_room_id.to_string()).await?;
    let timeline = room.timeline().await?;

    sisko_room
        .send(RoomMessageEventContent::text_plain("hello"))
        .await?;

    // ensure we received the message
    Retry::spawn(retry_strategy.clone(), || async {
        let Some(event) = timeline.latest_event().await else {
            bail!("no event");
        };
        let TimelineItemContent::MsgLike(MsgLikeContent {
            kind: MsgLikeKind::Message(msg),
            ..
        }) = event.content()
        else {
            bail!("not a text message");
        };
        if msg.body() == "hello" {
            Ok(true)
        } else {
            Err(anyhow::anyhow!("wrong message"))
        }
    })
    .await?;

    // without that triggereing an update

    assert_eq!(stream.next().now_or_never(), None);

    Ok(())
}

#[tokio::test]
async fn invitations_update_count_when_rejected() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut sisko, sisko_room_id) = random_user_with_random_space("spI").await?;
    let (mut worf, worf_room_id) = random_user_with_random_space("sp2").await?;
    let (mut gundom, gundom_room_id) = random_user_with_random_space("sp3").await?;
    let _sisko_syncer = sisko.start_sync();
    let _worf_syncer = worf.start_sync();
    let _gundom_syncer = gundom.start_sync();

    let mut kyra = random_user("spI").await?;
    let _kyra_syncer = kyra.start_sync();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let invites = kyra.invitations();
    let stream = invites.subscribe_stream();
    let mut stream = stream.fuse();

    invite_user(&sisko, &sisko_room_id, &kyra.user_id()?).await?;

    // sisko's invite

    let manager = invites.clone();

    let invited = Retry::spawn(retry_strategy.clone(), || async {
        let invited = manager.room_invitations().await?;
        if invited.is_empty() {
            Err(anyhow::anyhow!("No pending invitations found"))
        } else {
            Ok(invited)
        }
    })
    .await?;

    // stream triggered
    assert_eq!(stream.next().await, Some(true));

    assert_eq!(invited.len(), 1);
    let room = invited
        .first()
        .expect("first invitation should be available");
    assert_eq!(room.room_id(), sisko_room_id);
    assert_eq!(room.state(), RoomState::Invited);
    assert!(room.is_space());
    assert_eq!(room.sender_id(), sisko.user_id()?);

    // second stream

    invite_user(&worf, &worf_room_id, &kyra.user_id()?).await?;
    // and has been seen
    assert_eq!(stream.next().await, Some(true));

    invite_user(&gundom, &gundom_room_id, &kyra.user_id()?).await?;
    // and has been seen
    assert_eq!(stream.next().await, Some(true));

    room.reject().await?;
    let manager = invites.clone();

    Retry::spawn(retry_strategy.clone(), || async {
        let invited = manager.room_invitations().await?;
        if invited.len() != 2 {
            Err(anyhow::anyhow!("not yet updated"))
        } else {
            Ok(true)
        }
    })
    .await?;

    // we have seen an update on the stream as well
    assert_eq!(stream.next().await, Some(true));

    Ok(())
}
