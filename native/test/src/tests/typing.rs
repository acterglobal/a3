use anyhow::Result;

use crate::utils::random_users_with_random_space;

#[tokio::test]
async fn bob_detects_alice_typing() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut alice, mut bob, room_id) = random_users_with_random_space("typing").await?;

    let alice_syncer = alice.start_sync();
    alice_syncer.await_has_synced_history().await?;
    let space = alice.get_space(room_id.to_string()).await?;
    let sent = space.typing_notice(true).await?;
    println!("sent: {sent:?}");

    let bob_syncer = bob.start_sync();
    bob_syncer.await_has_synced_history().await?;
    let mut event_rx = bob.typing_event_rx().unwrap();

    loop {
        match event_rx.try_next() {
            Ok(Some(event)) => {
                println!("received: {event:?}");
                break;
            }
            Ok(None) => {
                println!("received: none");
            }
            Err(_e) => {}
        }
    }

    Ok(())
}
