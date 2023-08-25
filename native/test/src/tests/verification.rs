use acter::api::{login_new_client, VerificationEvent};
use anyhow::Result;
use futures::{channel::mpsc::Receiver, stream::StreamExt};
use tempfile::TempDir;
use tracing::info;

use crate::utils::default_user_password;

fn wait_for_verification_event(
    rx: &mut Receiver<VerificationEvent>,
    name: &str,
) -> VerificationEvent {
    loop {
        if let Ok(Some(event)) = rx.try_next() {
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

    let alice_dir = TempDir::new()?;
    let mut alice = login_new_client(
        alice_dir.path().to_str().expect("always works").to_string(),
        "@sisko".to_string(),
        default_user_password("sisko"),
        option_env!("DEFAULT_HOMESERVER_NAME")
            .unwrap_or("localhost")
            .to_string(),
        option_env!("DEFAULT_HOMESERVER_URL")
            .unwrap_or("http://localhost:8118")
            .to_string(),
        Some("ALICE_DEV".to_string()),
    )
    .await?;

    let alice_device_id = alice.device_id().expect("alice should get device id");
    info!("alice device id: {}", alice_device_id);

    let bob_dir = TempDir::new()?;
    let mut bob = login_new_client(
        bob_dir.path().to_str().expect("always works").to_string(),
        "@sisko".to_string(),
        default_user_password("sisko"),
        option_env!("DEFAULT_HOMESERVER_NAME")
            .unwrap_or("localhost")
            .to_string(),
        option_env!("DEFAULT_HOMESERVER_URL")
            .unwrap_or("http://localhost:8118")
            .to_string(),
        Some("BOB_DEV".to_string()),
    )
    .await?;

    let bob_device_id = bob.device_id().expect("bob should get device id");
    info!("bob device id: {}", bob_device_id);
    // we have two devices logged in

    // sync both up to ensure they've seen the other device
    let mut alice_device_changed_rx = alice.device_changed_event_rx().unwrap();
    let syncer = alice.start_sync();
    let mut first_synced = syncer.first_synced_rx();
    while first_synced.next().await != Some(true) {} // let's wait for it to have synced
    let mut alice_rx = alice.verification_event_rx().unwrap();

    let syncer = bob.start_sync();
    let mut first_synced = syncer.first_synced_rx();
    while first_synced.next().await != Some(true) {} // let's wait for it to have synced
    let mut bob_rx = bob.verification_event_rx().unwrap();

    // according to alice bob is not verfied:
    assert!(!alice.verified_device(bob_device_id.to_string()).await?);

    // according to bob alice is not verfied:
    assert!(!bob.verified_device(alice_device_id.to_string()).await?);

    // ----------------------------------------------------------------------------
    // On Alice's device:

    // Alice gets notified that new device (Bob) was logged in
    loop {
        if let Ok(Some(event)) = alice_device_changed_rx.try_next() {
            if let Ok(_devices) = event.device_records(false).await {
                // Alice sends a verification request with her desired methods to Bob
                event
                    .request_verification_to_device_with_methods(
                        bob_device_id.to_string(),
                        &mut vec!["m.sas.v1".to_string()],
                    )
                    .await?;
                break;
            }
        }
    }

    // ----------------------------------------------------------------------------
    // On Bob's device:

    // Bob receives the request event from Alice
    let event = wait_for_verification_event(&mut bob_rx, "m.key.verification.request");

    // Bob accepts the request, sending a Ready request
    event
        .accept_verification_request_with_methods(&mut vec!["m.sas.v1".to_string()])
        .await?;
    // And also immediately sends a start request
    let started = event.start_sas_verification().await?;
    assert!(started, "bob failed to start sas");

    // ----------------------------------------------------------------------------
    // On Alice's device:

    // Alice receives the ready event from Bob
    let event = wait_for_verification_event(&mut alice_rx, "m.key.verification.ready");

    // Alice immediately sends a start request
    let started = event.start_sas_verification().await?;
    assert!(started, "alice failed to start sas verification");

    // Now Alice receives the start event from Bob
    // Without this loop, sometimes the cancel event follows the start event
    wait_for_verification_event(&mut alice_rx, "m.key.verification.start");

    // ----------------------------------------------------------------------------
    // On Bob's device:

    // Bob receives the start event from Alice
    let event = wait_for_verification_event(&mut bob_rx, "m.key.verification.start");

    // Bob accepts it
    let accepted = event.accept_sas_verification().await?;
    assert!(accepted, "bob failed to accept sas verification");

    // ----------------------------------------------------------------------------
    // On Alice's device:

    // Alice receives the accept event from Bob
    let event = wait_for_verification_event(&mut alice_rx, "m.key.verification.accept");

    // Alice sends a key
    event.send_verification_key().await?;

    // ----------------------------------------------------------------------------
    // On Bob's device:

    // Bob receives the key event from Alice
    let bob_event = wait_for_verification_event(&mut bob_rx, "m.key.verification.key");

    // Bob gets the verification key from event
    let emojis_from_alice = bob_event.get_emojis();
    info!("emojis from alice: {:?}", emojis_from_alice);

    // Bob sends a key
    bob_event.send_verification_key().await?;

    // ----------------------------------------------------------------------------
    // On Alice's device:

    // Alice receives the key event from Bob
    let alice_event = wait_for_verification_event(&mut alice_rx, "m.key.verification.key");

    // Alice gets the verification key from event
    let emojis_from_bob = alice_event.get_emojis();
    info!("emojis from bob: {:?}", emojis_from_bob);

    // ----------------------------------------------------------------------------
    // On Bob's device:

    // Bob first confirms that the emojis match and sends the mac event...
    bob_event.confirm_sas_verification().await?;

    // ----------------------------------------------------------------------------
    // On Alice's device:

    // Alice first confirms that the emojis match and sends the mac event...
    alice_event.confirm_sas_verification().await?;

    // ----------------------------------------------------------------------------
    // On Bob's device:

    // Bob receives the mac event from Alice
    wait_for_verification_event(&mut bob_rx, "m.key.verification.mac");

    // ----------------------------------------------------------------------------
    // On Alice's device:

    // Alice receives the mac event from Bob
    wait_for_verification_event(&mut alice_rx, "m.key.verification.mac");

    // ----------------------------------------------------------------------------
    // On Bob's device:

    // Bob receives the done event from Alice
    wait_for_verification_event(&mut bob_rx, "m.key.verification.done");

    // ----------------------------------------------------------------------------
    // On Alice's device:

    // Alice receives the done event from Bob
    wait_for_verification_event(&mut alice_rx, "m.key.verification.done");

    Ok(())
}
