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
    Retry::spawn(retry_strategy, || async {
        user.space(room_id.to_string()).await
    })
    .await?;

    let _space = user.space(room_id.to_string()).await?;
    let super_invites = user.super_invites();
    let tokens = super_invites.tokens().await?;
    assert_eq!(tokens.len(), 0); // we start with zero tokens

    // let’s create a new one
    let mut token_builder = SuperInvitesTokenUpdateBuilder::new();
    let given_token = "1234567890"; // will not use the auto-generated token string
    token_builder.token(given_token.to_owned());
    token_builder.add_room(room_id.to_string());

    let token = super_invites
        .create_or_update_token(Box::new(token_builder))
        .await?;
    assert_eq!(token.accepted_count(), 0);
    let rooms = token.rooms();
    assert_eq!(rooms.len(), 1);
    assert_eq!(rooms[0], room_id);

    let token_str = token.token();
    assert_eq!(token_str, given_token);

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
    Retry::spawn(retry_strategy, || async {
        user.space(room_id.to_string()).await
    })
    .await?;

    let _space = user.space(room_id.to_string()).await?;
    let super_invites = user.super_invites();
    let tokens = super_invites.tokens().await?;
    assert_eq!(tokens.len(), 0); // we start with zero tokens

    // let’s create a new one

    let mut token_builder = SuperInvitesTokenUpdateBuilder::new();
    token_builder.add_room(room_id.to_string());
    let token = super_invites
        .create_or_update_token(Box::new(token_builder))
        .await?;
    let rooms = token.rooms();
    assert_eq!(rooms.len(), 1);
    assert_eq!(rooms[0], room_id);
    assert!(!token.create_dm());

    let tokens = super_invites.tokens().await?;
    assert_eq!(tokens.len(), 1); // we start with zero tokens

    let mut token_builder = token.update_builder();
    token_builder.remove_room(room_id.to_string());
    token_builder.create_dm(true);
    let token = super_invites
        .create_or_update_token(Box::new(token_builder))
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
