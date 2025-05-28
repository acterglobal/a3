use acter::api::SuperInvitesTokenUpdateBuilder;
use anyhow::Result;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::{random_user_under_token, random_user_with_random_space};

#[tokio::test]
async fn super_invites_flow_with_registration_and_rooms() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("super_invites_flow").await?;

    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.space(room_id.to_string()).await }
    })
    .await?;

    let _space = user.space(room_id.to_string()).await?;
    let super_invites = user.super_invites();
    let tokens = super_invites.tokens().await?;
    assert_eq!(tokens.len(), 0); // we start with zero tokens

    // let’s create a new one
    let builder = SuperInvitesTokenUpdateBuilder::new().add_room(room_id.to_string());

    let token = super_invites
        .create_or_update_token(Box::new(builder.clone()))
        .await?;
    assert_eq!(token.accepted_count(), 0);
    let rooms = token.rooms();
    assert_eq!(rooms.len(), 1);
    assert_eq!(rooms[0], room_id);

    let token_str = token.token();

    let tokens = super_invites.tokens().await?;
    assert_eq!(tokens.len(), 1); // we have one now

    // try to use that token as registration
    let mut new_user = random_user_under_token("super_invites_flow_other", &token_str).await?;
    let new_super_invites = new_user.super_invites();
    let new_rooms = new_super_invites.redeem(token_str).await?;
    assert_eq!(new_rooms.len(), 1);
    assert_eq!(new_rooms[0], room_id);

    let state_sync = new_user.start_sync();
    state_sync.await_has_synced_history().await?;
    let _space = new_user.space(room_id.to_string()).await?; // we are part of that space now! yay!

    // and the tracker shows it:

    let tokens = super_invites.tokens().await?;
    assert_eq!(tokens.len(), 1);
    assert_eq!(tokens[0].accepted_count(), 1);

    Ok(())
}

#[tokio::test]
async fn super_invites_manage() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("super_invites_manage").await?;

    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.space(room_id.to_string()).await }
    })
    .await?;

    let _space = user.space(room_id.to_string()).await?;
    let super_invites = user.super_invites();
    let tokens = super_invites.tokens().await?;
    assert_eq!(tokens.len(), 0); // we start with zero tokens

    // let’s create a new one

    let builder = SuperInvitesTokenUpdateBuilder::new().add_room(room_id.to_string());
    let token = super_invites
        .create_or_update_token(Box::new(builder.clone()))
        .await?;
    let rooms = token.rooms();
    assert_eq!(rooms.len(), 1);
    assert_eq!(rooms[0], room_id);
    assert!(!token.create_dm());

    let tokens = super_invites.tokens().await?;
    assert_eq!(tokens.len(), 1); // we start with zero tokens

    let builder = token
        .update_builder()
        .remove_room(room_id.to_string())
        .create_dm(true);
    let token = super_invites
        .create_or_update_token(Box::new(builder.clone()))
        .await?;
    let rooms = token.rooms();
    assert_eq!(rooms.len(), 0);
    assert!(token.create_dm());

    let token_str = token.token();

    // now delete it
    assert!(super_invites.delete(token_str).await?);
    let tokens = super_invites.tokens().await?;
    assert_eq!(tokens.len(), 0); // we start with zero tokens

    Ok(())
}
