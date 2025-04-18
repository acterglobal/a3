use anyhow::Result;
use futures::StreamExt;
use matrix_sdk::RoomState;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::{random_user, random_user_with_random_convo, random_user_with_random_space};

#[tokio::test]
async fn chat_invitation_shows_up() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut sisko, room_id) = random_user_with_random_convo("cI").await?;
    let _sisko_syncer = sisko.start_sync();

    let mut kyra = random_user("cI").await?;
    let _kyra_syncer = kyra.start_sync();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);

    let convo = Retry::spawn(retry_strategy.clone(), || async {
        sisko.convo(room_id.as_str().into()).await
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
    let room = invited.first().unwrap();
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

    let space = Retry::spawn(retry_strategy.clone(), || async {
        sisko.space(room_id.as_str().into()).await
    })
    .await?;

    let invites = kyra.invitations();
    let stream = invites.subscribe_stream();
    let mut stream = stream.fuse();
    space.invite_user_by_id(&kyra.user_id()?).await?;

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
    let room = invited.first().unwrap();
    assert_eq!(room.room_id(), room_id);
    assert_eq!(room.state(), RoomState::Invited);
    assert!(room.is_space());
    assert_eq!(room.sender_id(), sisko.user_id()?);

    Ok(())
}
