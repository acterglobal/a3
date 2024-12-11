use acter::api::VerificationEvent;
use anyhow::Result;
use futures::{
    pin_mut,
    stream::{Stream, StreamExt},
    FutureExt,
};
use tracing::info;

use crate::utils::random_user;

fn wait_for_verification_event(
    rx: impl Stream<Item = VerificationEvent>,
    name: &str,
) -> VerificationEvent {
    pin_mut!(rx);
    loop {
        if let Some(event) = rx.next().now_or_never().flatten() {
            if event.event_type() == name {
                return event;
            }
        }
    }
}

#[tokio::test]
#[ignore = "test runs forever in both github runner and local synapse :("]
async fn interactive_verification_started_from_request() -> Result<()> {
    let _ = env_logger::try_init();

    let mut alice = random_user("interactive_verification_started_from_request_alice").await?;

    let alice_device_id = alice.device_id().expect("alice should get device id");
    info!("alice device id: {}", alice_device_id);

    let mut bob = random_user("interactive_verification_started_from_request_bob").await?;

    let bob_device_id = bob.device_id().expect("bob should get device id");
    info!("bob device id: {}", bob_device_id);
    // we have two devices logged in

    // sync both up to ensure they’ve seen the other device
    let mut alice_device_rx = alice.device_event_rx();
    let syncer = alice.start_sync();
    let mut first_synced = syncer.first_synced_rx();
    while first_synced.next().await != Some(true) {} // let’s wait for it to have synced
    let mut alice_rx = alice.verification_event_rx();

    let syncer = bob.start_sync();
    let mut first_synced = syncer.first_synced_rx();
    while first_synced.next().await != Some(true) {} // let’s wait for it to have synced
    let mut bob_rx = bob.verification_event_rx();

    // according to alice bob is not verfied:
    let bob_was_verified = alice.verified_device(bob_device_id.to_string()).await?;
    assert!(!bob_was_verified);

    // according to bob alice is not verfied:
    let alice_was_verified = bob.verified_device(alice_device_id.to_string()).await?;
    assert!(!alice_was_verified);

    // ----------------------------------------------------------------------------
    // On Alice’s device:

    // Alice gets notified that new device (Bob) was logged in
    loop {
        if let Some(_event) = alice_device_rx.next().await {
            if let Ok(_devices) = alice.device_records(false).await {
                // Alice sends a verification request with her desired methods to Bob
                alice
                    .request_verification_with_method(
                        bob_device_id.to_string(),
                        "m.sas.v1".to_string(),
                    )
                    .await?;
                break;
            }
        }
    }

    // ----------------------------------------------------------------------------
    // On Bob’s device:

    // Bob receives the request event from Alice
    let event = wait_for_verification_event(&mut bob_rx, "m.key.verification.request");

    // Bob accepts the request, sending a Ready request
    event
        .accept_verification_request_with_method("m.sas.v1".to_string())
        .await?;
    // And also immediately sends a start request
    let started = event.start_sas_verification().await?;
    assert!(started, "bob failed to start sas");

    // ----------------------------------------------------------------------------
    // On Alice’s device:

    // Alice receives the ready event from Bob
    let event = wait_for_verification_event(&mut alice_rx, "m.key.verification.ready");

    // Alice immediately sends a start request
    let started = event.start_sas_verification().await?;
    assert!(started, "alice failed to start sas verification");

    // Now Alice receives the start event from Bob
    // Without this loop, sometimes the cancel event follows the start event
    wait_for_verification_event(&mut alice_rx, "m.key.verification.start");

    // ----------------------------------------------------------------------------
    // On Bob’s device:

    // Bob receives the start event from Alice
    let event = wait_for_verification_event(&mut bob_rx, "m.key.verification.start");

    // Bob accepts it
    let accepted = event.accept_sas_verification().await?;
    assert!(accepted, "bob failed to accept sas verification");

    // ----------------------------------------------------------------------------
    // On Alice’s device:

    // Alice receives the accept event from Bob
    let event = wait_for_verification_event(&mut alice_rx, "m.key.verification.accept");

    // Alice sends a key
    event.send_verification_key().await?;

    // ----------------------------------------------------------------------------
    // On Bob’s device:

    // Bob receives the key event from Alice
    let bob_event = wait_for_verification_event(&mut bob_rx, "m.key.verification.key");

    // Bob gets the verification key from event
    let emojis_from_alice = bob_event.get_emojis().await?;
    info!("emojis from alice: {:?}", emojis_from_alice);

    // Bob sends a key
    bob_event.send_verification_key().await?;

    // ----------------------------------------------------------------------------
    // On Alice’s device:

    // Alice receives the key event from Bob
    let alice_event = wait_for_verification_event(&mut alice_rx, "m.key.verification.key");

    // Alice gets the verification key from event
    let emojis_from_bob = alice_event.get_emojis().await?;
    info!("emojis from bob: {:?}", emojis_from_bob);

    // ----------------------------------------------------------------------------
    // On Bob’s device:

    // Bob first confirms that the emojis match and sends the mac event...
    bob_event.confirm_sas_verification().await?;

    // ----------------------------------------------------------------------------
    // On Alice’s device:

    // Alice first confirms that the emojis match and sends the mac event...
    alice_event.confirm_sas_verification().await?;

    // ----------------------------------------------------------------------------
    // On Bob’s device:

    // Bob receives the mac event from Alice
    wait_for_verification_event(&mut bob_rx, "m.key.verification.mac");

    // ----------------------------------------------------------------------------
    // On Alice’s device:

    // Alice receives the mac event from Bob
    wait_for_verification_event(&mut alice_rx, "m.key.verification.mac");

    // ----------------------------------------------------------------------------
    // On Bob’s device:

    // Bob receives the done event from Alice
    wait_for_verification_event(&mut bob_rx, "m.key.verification.done");

    // ----------------------------------------------------------------------------
    // On Alice’s device:

    // Alice receives the done event from Bob
    wait_for_verification_event(&mut alice_rx, "m.key.verification.done");

    Ok(())
}
