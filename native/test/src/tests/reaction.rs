use acter::matrix_sdk::ruma::events::{AnyMessageLikeEvent, AnyTimelineEvent, MessageLikeEvent};
use anyhow::{bail, Result};

use crate::utils::random_users_with_random_space;

#[tokio::test]
async fn alice_reads_reactions_from_bob() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut alice, mut bob, room_id) = random_users_with_random_space("reaction").await?;

    let alice_syncer = alice.start_sync();
    alice_syncer.await_has_synced_history().await?;
    let alice_space = alice.get_space(room_id.to_string()).await?;
    let event_id = alice_space
        .send_plain_message("Hi, everyone".to_string())
        .await?;

    let bob_syncer = bob.start_sync();
    bob_syncer.await_has_synced_history().await?;
    let bob_space = bob.get_space(room_id.to_string()).await?;
    let reaction_id = bob_space
        .send_reaction(event_id.to_string(), "👏".to_string())
        .await?;

    let ev = alice_space.event(&reaction_id).await?;
    println!("reaction: {ev:?}");

    let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::Reaction(MessageLikeEvent::Original(m)))) = ev.event.deserialize() else {
        bail!("Could not deserialize event");
    };

    assert_eq!(m.content.relates_to.key, "👏".to_string());

    Ok(())
}
