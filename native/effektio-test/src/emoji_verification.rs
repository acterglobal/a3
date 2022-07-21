use anyhow::Result;
use effektio::api::{device_id, login_new_client, RumaUserId, VerificationMethod};
use futures::stream::StreamExt;
use tempfile::TempDir;
use tokio::time::{sleep, Duration};

#[tokio::test]
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
    let device_id = alice.device_id().await.expect("alice should get device id");
    let alice_enc = alice.encryption();
    let alice_device = alice_enc.get_device(&alice_user_id, device_id!(device_id.as_str())).await.expect("alice should get device").unwrap();

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
    let device_id = bob.device_id().await.expect("bob should get device id");
    let bob_enc = bob.encryption();
    let bob_device = bob_enc.get_device(&bob_user_id, device_id!(device_id.as_str())).await.expect("bob should get device").unwrap();

    // ----------------------------------------------------------------------------
    // On Alice's device:
    assert!(!bob_device.verified());

    // Alice sends a verification request with her desired methods to Bob
    let alice_ver_req = bob_device.request_verification_with_methods(vec![VerificationMethod::SasV1]).await?;

    // ----------------------------------------------------------------------------
    // On Bobs's device:
    let mut sender: Option<String> = None;
    let mut event_id: Option<String> = None;
    loop {
        if let Ok(Some(event)) = bob_rx.try_next() {
            if event.get_event_name().as_str() == "AnyToDeviceEvent::KeyVerificationRequest" {
                sender = Some(event.get_sender());
                event_id = Some(event.get_event_id());
                break;
            }
        }
    }
    assert!(sender.is_some());
    assert!(event_id.is_some());
    let user_id = RumaUserId::parse(sender.unwrap().as_str())?;
    let verification_request = bob_enc.get_verification_request(&user_id, event_id.unwrap()).await.unwrap();

    // Bob accepts the request, sending a Ready request
    verification_request.accept_with_methods(vec![VerificationMethod::SasV1]).await?;
    // And also immediately sends a start request
    let start_request_from_bob = verification_request.start_sas().await?;

    // ----------------------------------------------------------------------------
    // On Alice's device:
    sender = None;
    event_id = None;
    println!("123");
    loop {
        if let Ok(Some(event)) = alice_rx.try_next() {
            println!("alice event: {:?}", event);
            if event.get_event_name().as_str() == "AnyToDeviceEvent::KeyVerificationStart" {
                sender = Some(event.get_sender());
                event_id = Some(event.get_event_id());
                break;
            }
        }
    }
    assert!(sender.is_some());
    assert!(event_id.is_some());
    println!("456");

    Ok(())
}
