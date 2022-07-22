use anyhow::Result;
use effektio::api::{device_id, login_new_client, VerificationMethod};
use futures::stream::StreamExt;
use tempfile::TempDir;

#[tokio::test]
async fn interactive_verification_started_from_request() -> Result<()> {
    let _ = env_logger::try_init();

    let alice_dir = TempDir::new()?;
    let alice = login_new_client(
        alice_dir.path().to_str().expect("always works").to_owned(),
        "@sisko:ds9.effektio.org".to_owned(),
        "sisko".to_owned(),
    )
    .await?;

    let alice_user_id = alice.user_id().await.expect("alice should get user id");
    let alice_device_id = alice.device_id().await.expect("alice should get device id");
    let alice_enc = alice.encryption();

    let bob_dir = TempDir::new()?;
    let bob = login_new_client(
        bob_dir.path().to_str().expect("always works").to_owned(),
        "@sisko:ds9.effektio.org".to_owned(),
        "sisko".to_owned(),
    )
    .await?;

    let bob_user_id = bob.user_id().await.expect("bob should get user id");
    let bob_device_id = bob.device_id().await.expect("bob should get device id");
    let bob_enc = bob.encryption();
    // we have two devices logged in

    // sync both up to ensure they've seen the other device
    let syncer = alice.start_sync();
    let mut first_synced = syncer.get_first_synced_rx().expect("not yet read");
    while first_synced.next().await != Some(true) {} // let's wait for it to ha
    let mut alice_rx = syncer.get_emoji_verification_event_rx().unwrap();

    let syncer = bob.start_sync();
    let mut first_synced = syncer.get_first_synced_rx().expect("not yet read");
    while first_synced.next().await != Some(true) {} // let's wait for it to have synced
    let mut bob_rx = syncer.get_emoji_verification_event_rx().unwrap();

    // alice tries to find bob's device.
    let bob_device = alice_enc
        .get_device(&alice_user_id, &device_id!(bob_device_id.as_str()))
        .await
        .expect("alice should get device")
        .unwrap();

    // according to alice bob is not verfied:
    assert!(!bob_device.verified());

    // bob tries to find alice's device.
    let alice_device = bob_enc
        .get_device(&bob_user_id, &device_id!(alice_device_id.as_str()))
        .await
        .expect("bob should get device")
        .unwrap();

    // according to bob alice is not verfied:
    assert!(!alice_device.verified());

    // ----------------------------------------------------------------------------

    // Alice sends a verification request with her desired methods to Bob
    let alice_verif_req = bob_device
        .request_verification_with_methods(vec![VerificationMethod::SasV1])
        .await?;

    // ----------------------------------------------------------------------------
    // On Bob's device:

    // Bob receives the request event from Alice
    let mut sender: Option<String> = None;
    let mut txn_id: Option<String> = None;
    loop {
        if let Ok(Some(event)) = bob_rx.try_next() {
            if event.get_event_name().as_str() == "m.key.verification.request" {
                sender = Some(event.get_sender());
                txn_id = Some(event.get_txn_id());
                break;
            }
        }
    }
    assert!(sender.is_some());
    assert!(txn_id.is_some());
    let _sender = sender.unwrap();
    let _txn_id = txn_id.unwrap();

    // Bob accepts the request, sending a Ready request
    bob.accept_verification_request_with_methods(
        _sender.clone(),
        _txn_id.clone(),
        &mut vec!["m.sas.v1".to_owned()],
    )
    .await?;
    // And also immediately sends a start request
    let started = bob.start_sas_verification(_sender, _txn_id).await?;
    assert!(started, "bob failed to start sas");

    // ----------------------------------------------------------------------------
    // On Alice's device:

    // Alice receives the ready event from Bob
    let mut sender = None;
    let mut txn_id = None;
    loop {
        if let Ok(Some(event)) = alice_rx.try_next() {
            if event.get_event_name().as_str() == "m.key.verification.ready" {
                sender = Some(event.get_sender());
                txn_id = Some(event.get_txn_id());
                break;
            }
        }
    }
    assert!(sender.is_some());
    assert!(txn_id.is_some());

    // Alice immediately sends a start request
    let started = alice
        .start_sas_verification(sender.unwrap(), txn_id.unwrap())
        .await?;
    assert!(started, "alice failed to start sas verification");

    // Now Alice receives the start event from Bob
    // Without this loop, sometimes the cancel event follows the start event
    loop {
        if let Ok(Some(event)) = alice_rx.try_next() {
            if event.get_event_name().as_str() == "m.key.verification.start" {
                break;
            }
        }
    }

    // ----------------------------------------------------------------------------
    // On Bob's device:

    // Bob receives the start event from Alice
    let mut sender = None;
    let mut txn_id = None;
    loop {
        if let Ok(Some(event)) = bob_rx.try_next() {
            if event.get_event_name().as_str() == "m.key.verification.start" {
                sender = Some(event.get_sender());
                txn_id = Some(event.get_txn_id());
                break;
            }
        }
    }
    assert!(sender.is_some());
    assert!(txn_id.is_some());

    // Bob accepts it
    let accepted = bob
        .accept_sas_verification(sender.unwrap(), txn_id.unwrap())
        .await?;
    assert!(accepted, "bob failed to accept sas verification");

    // ----------------------------------------------------------------------------
    // On Alice's device:

    // Alice receives the accept event from Bob
    loop {
        if let Ok(Some(event)) = alice_rx.try_next() {
            if event.get_event_name().as_str() == "m.key.verification.accept" {
                break;
            }
        }
    }

    // Alice sends a key
    alice.send_verification_key().await?;

    // ----------------------------------------------------------------------------
    // On Bob's device:

    // Bob receives the key event from Alice
    let mut sender = None;
    let mut txn_id = None;
    loop {
        if let Ok(Some(event)) = bob_rx.try_next() {
            if event.get_event_name().as_str() == "m.key.verification.key" {
                sender = Some(event.get_sender());
                txn_id = Some(event.get_txn_id());
                break;
            }
        }
    }
    assert!(sender.is_some());
    assert!(txn_id.is_some());

    // Bob gets the verification key from event
    let emoji_from_alice = bob
        .get_verification_emoji(sender.unwrap(), txn_id.unwrap())
        .await?;
    println!("emoji from alice: {:?}", emoji_from_alice);

    // Bob sends a key
    bob.send_verification_key().await?;

    // ----------------------------------------------------------------------------
    // On Alice's device:

    // Alice receives the key event from Bob
    let mut sender = None;
    let mut txn_id = None;
    loop {
        if let Ok(Some(event)) = alice_rx.try_next() {
            if event.get_event_name().as_str() == "m.key.verification.key" {
                sender = Some(event.get_sender());
                txn_id = Some(event.get_txn_id());
                break;
            }
        }
    }
    assert!(sender.is_some());
    assert!(txn_id.is_some());
    let _sender = sender.unwrap();
    let _txn_id = txn_id.unwrap();

    // Alice gets the verification key from event
    let emoji_from_bob = alice
        .get_verification_emoji(_sender.clone(), _txn_id.clone())
        .await?;
    println!("emoji from bob: {:?}", emoji_from_bob);

    // ----------------------------------------------------------------------------
    // On Bob's device:

    // Bob first confirms that the emojis match and sends the mac event...
    bob.confirm_sas_verification(_sender.clone(), _txn_id.clone())
        .await?;

    // ----------------------------------------------------------------------------
    // On Alice's device:

    // Alice first confirms that the emojis match and sends the mac event...
    alice.confirm_sas_verification(_sender, _txn_id).await?;

    // ----------------------------------------------------------------------------
    // On Bob's device:

    // Bob receives the mac event from Alice
    loop {
        if let Ok(Some(event)) = bob_rx.try_next() {
            if event.get_event_name().as_str() == "m.key.verification.mac" {
                break;
            }
        }
    }

    // ----------------------------------------------------------------------------
    // On Alice's device:

    // Alice receives the mac event from Bob
    loop {
        if let Ok(Some(event)) = alice_rx.try_next() {
            if event.get_event_name().as_str() == "m.key.verification.mac" {
                break;
            }
        }
    }

    // ----------------------------------------------------------------------------
    // On Bob's device:

    // Bob receives the done event from Alice
    loop {
        if let Ok(Some(event)) = bob_rx.try_next() {
            if event.get_event_name().as_str() == "m.key.verification.done" {
                break;
            }
        }
    }

    // ----------------------------------------------------------------------------
    // On Alice's device:

    // Alice receives the done event from Bob
    loop {
        if let Ok(Some(event)) = alice_rx.try_next() {
            if event.get_event_name().as_str() == "m.key.verification.done" {
                break;
            }
        }
    }

    Ok(())
}
