use anyhow::Result;

use crate::utils::random_users_with_random_space;

#[tokio::test]
async fn alice_detects_bob_read() -> Result<()> {
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
    bob_space.read_receipt(event_id.to_string()).await?;

    let mut event_rx = alice.receipt_event_rx().unwrap();
    loop {
        match event_rx.try_next() {
            Ok(Some(event)) => {
                let mut found = false;
                for record in event.receipt_records() {
                    if record.seen_by() == bob.user_id()?.to_string() {
                        found = true;
                        break;
                    }
                }
                if found {
                    println!("received: {event:?}");
                    break;
                }
            }
            Ok(None) => {
                println!("received: none");
            }
            Err(_e) => {}
        }
    }

    Ok(())
}
