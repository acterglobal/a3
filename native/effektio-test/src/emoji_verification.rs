use anyhow::Result;
use effektio::api::{device_id, login_new_client, VerificationMethod};
use futures::stream::StreamExt;
use tempfile::TempDir;
use tokio::time::{sleep, Duration};

#[tokio::test(flavor = "multi_thread", worker_threads = 4)]
async fn interactive_verification_started_from_request() -> Result<()> {
    let _ = env_logger::try_init();

    let tmp_dir = TempDir::new()?;
    let alice = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@sisko:ds9.effektio.org".to_owned(),
        "sisko".to_owned(),
    )
    .await?;
    let syncer = alice.start_sync();
    let mut first_synced = syncer.get_first_synced_rx().expect("not yet read");
    while first_synced.next().await != Some(true) {} // let's wait for it to have synced
    let mut alice_rx = syncer.get_emoji_verification_event_rx().unwrap();

    let alice_user_id = alice.user_id().await.expect("alice should get user id");
    let alice_device_id = alice.device_id().await.expect("alice should get device id");
    let alice_enc = alice.encryption();
    let alice_device = alice_enc.get_device(&alice_user_id, device_id!(alice_device_id.as_str())).await.expect("alice should get device").unwrap();

    let tmp_dir = TempDir::new()?;
    let bob = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@sisko:ds9.effektio.org".to_owned(),
        "sisko".to_owned(),
    )
    .await?;
    let syncer = bob.start_sync();
    let mut first_synced = syncer.get_first_synced_rx().expect("not yet read");
    while first_synced.next().await != Some(true) {} // let's wait for it to have synced
    let mut bob_rx = syncer.get_emoji_verification_event_rx().unwrap();

    let bob_user_id = bob.user_id().await.expect("bob should get user id");
    let bob_device_id = bob.device_id().await.expect("bob should get device id");
    let bob_enc = bob.encryption();
    let bob_device = bob_enc.get_device(&bob_user_id, device_id!(bob_device_id.as_str())).await.expect("bob should get device").unwrap();

    // ----------------------------------------------------------------------------
    // Two devices must be unique
    println!("alice device id: {}", alice_device_id);
    println!("bob device id: {}", bob_device_id);
    assert!(alice_device_id != bob_device_id, "two devices must be unique");

    // ----------------------------------------------------------------------------
    // On Alice's device:
    assert!(!bob_device.verified());

    // Alice sends a verification request with her desired methods to Bob
    let alice_ver_req = bob_device.request_verification_with_methods(vec![VerificationMethod::SasV1]).await?;
    let flow_id = alice_ver_req.flow_id();
    println!("alice created flow id: {}", flow_id);

    // ----------------------------------------------------------------------------
    // On Bob's device:
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
    let _sender = sender.unwrap();
    let _txn_id = txn_id.unwrap();
    assert!(_sender.as_str() == "@sisko:ds9.effektio.org", "bob got wrong sender");
    assert!(_txn_id == flow_id, "bob got wrong transaction id");
    // Bob accepts the request, sending a Ready request
    bob.accept_verification_request_with_methods(_sender.clone(), _txn_id.clone(), vec!["m.sas.v1".to_owned()]).await?;
    // And also immediately sends a start request
    let started = bob.start_sas_verification(_sender, _txn_id).await?;
    println!("started: {}", started);
    // assert!(started, "bob failed to start sas");

    // ----------------------------------------------------------------------------
    // On Alice's device:
    sender = None;
    txn_id = None;
    loop {
        if let Ok(Some(event)) = alice_rx.try_next() {
            println!("alice event: {:?}", event);
            if event.get_event_name().as_str() == "m.key.verification.ready" {
                sender = Some(event.get_sender());
                txn_id = Some(event.get_txn_id());
                break;
            }
        }
    }
    let _sender = sender.unwrap();
    let _txn_id = txn_id.unwrap();
    println!("123");
    assert!(_sender.as_str() == "@sisko:ds9.effektio.org", "alice got wrong sender");
    assert!(_txn_id == flow_id, "alice got wrong transaction id");
    alice.accept_verification_start(_sender, _txn_id).await?;

    Ok(())
}
