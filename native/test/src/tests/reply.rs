use acter::matrix_sdk::ruma::events::{AnyMessageLikeEvent, AnyTimelineEvent, MessageLikeEvent};
use anyhow::{bail, Result};

use crate::utils::random_users_with_random_space;

#[tokio::test]
async fn bob_replies_to_alice() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut alice, mut bob, room_id) = random_users_with_random_space("reply").await?;

    let alice_syncer = alice.start_sync();
    alice_syncer.await_has_synced_history().await?;
    let alice_space = alice.get_space(room_id.to_string()).await?;
    let event_id = alice_space
        .send_plain_message("Hi, everyone".to_string())
        .await?;

    let bob_syncer = bob.start_sync();
    bob_syncer.await_has_synced_history().await?;
    let bob_space = bob.get_space(room_id.to_string()).await?;
    let reply_id = bob_space
        .send_text_reply("Sorry, it's my bad".to_string(), event_id.to_string(), None)
        .await?;

    let ev = bob_space.event(&reply_id).await?;
    println!("reply: {ev:?}");

    let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(MessageLikeEvent::Original(m)))) = ev.event.deserialize() else {
        bail!("Could not deserialize event");
    };

    assert_eq!(
        m.content.body(),
        format!(
            "> <{}> Hi, everyone\n\nSorry, it's my bad",
            alice.user_id()?.to_string(),
        )
    );

    Ok(())
}
