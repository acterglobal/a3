use acter::api::{login_new_client, Client, VerificationRequestEvent};
use anyhow::{Context, Result};
use futures::{
    future::FutureExt,
    pin_mut,
    stream::{Stream, StreamExt},
};
use tempfile::TempDir;
use tracing::info;

use crate::utils::{default_user_password, random_user};

fn wait_for_verification_request_event(
    rx: impl Stream<Item = VerificationRequestEvent>,
) -> VerificationRequestEvent {
    pin_mut!(rx);
    loop {
        if let Some(event) = rx.next().now_or_never().flatten() {
            return event;
        }
    }
}

async fn request_session_verification(
    verifier_client: &Client,
    verifiee_device_id: String,
) -> Result<VerificationRequestEvent> {
    // let mut device_rx = verifier_client.device_event_rx();
    // loop {
    //     info!("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
    //     if let Some(_event) = device_rx.next().await {
    //         info!("yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy");
    //         // Alice gets notified that new device (Bob) was logged in
    //         if let Ok(_devices) = verifier_client.device_records(false).await {
    //             info!("zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz");
    //             // Alice sends a verification request to Bob
    //             let request_event = verifier_client
    //                 .request_session_verification(verifiee_device_id.to_string())
    //                 .await?;
    //             return Ok(request_event);
    //         }
    //     }
    // }

    // Alice sends a verification request to Bob
    let request_event = verifier_client
        .request_session_verification(verifiee_device_id.to_string())
        .await?;
    return Ok(request_event);
}

#[tokio::test]
async fn complete_verification() -> Result<()> {
    let _ = env_logger::try_init();

    // ----------------------------------------------------------------------------
    // Construct two clients for single user
    // It means two devices are logged in for single user

    let mut alice = random_user("sisko").await?;
    let user_id = alice.user_id()?;
    let username = user_id.localpart();

    let alice_device_id = alice.device_id().expect("alice should get device id");
    info!("alice device id: {}", alice_device_id);

    let tmp_dir = TempDir::new()?;
    let mut bob = login_new_client(
        tmp_dir.path().to_string_lossy().to_string(),
        tmp_dir.path().to_string_lossy().to_string(),
        username.to_owned(),
        default_user_password(username),
        option_env!("DEFAULT_HOMESERVER_NAME")
            .unwrap_or("localhost")
            .to_string(),
        option_env!("DEFAULT_HOMESERVER_URL")
            .unwrap_or("http://localhost:8118")
            .to_string(),
        Some("SISKO_DEV".to_string()),
    )
    .await?;

    let bob_device_id = bob.device_id().expect("bob should get device id");
    info!("bob device id: {}", bob_device_id);
    // we have two devices logged in

    // sync both up to ensure they’ve seen the other device
    let syncer = alice.start_sync();
    let mut first_synced = syncer.first_synced_rx();
    while first_synced.next().await != Some(true) {} // let’s wait for it to have synced

    let syncer = bob.start_sync();
    let mut first_synced = syncer.first_synced_rx();
    while first_synced.next().await != Some(true) {} // let’s wait for it to have synced
    let mut bob_rx = bob.verification_request_event_rx().await?;

    // according to alice, bob is not verfied:
    let bob_was_verified = alice.verified_device(bob_device_id.to_string()).await?;
    assert!(!bob_was_verified);

    // according to bob, alice is not verfied:
    let alice_was_verified = bob.verified_device(alice_device_id.to_string()).await?;
    assert!(!alice_was_verified);

    // Alice requests verification for Bob
    let alice_event = request_session_verification(&alice, bob_device_id.to_string()).await?;

    // Bob receives the request event from Alice
    let bob_event = wait_for_verification_request_event(&mut bob_rx);

    // Both install the monitor of verification request events
    alice_event.acknowledge().await?;
    bob_event.acknowledge().await?;

    // Alice accepts her request
    let alice_ready_stage = alice_event.accept().await?;

    // Bob accepts the request from Alice
    let bob_ready_stage = bob_event.accept().await?;

    info!("111111111111111111111111111111111111111111111111");
    // Both start SAS
    let alice_prompt_stage = alice_ready_stage.start_sas().await?;
    let bob_prompt_stage = bob_ready_stage.start_sas().await?;

    info!("22222222222222222222222222222222222222222222");
    // Both get emojis
    let alice_data = alice_prompt_stage.get_emojis().await?;
    let alice_emojis = alice_data.emojis().context("Alice should have emojis")?;
    let bob_data = bob_prompt_stage.get_emojis().await?;
    let bob_emojis = bob_data.emojis().context("Bob should have emojis")?;

    info!("33333333333333333333333333333333333333333333333");
    // Alice compares her emojis with Bob's emojis
    let alice_len = alice_emojis.len();
    let bob_len = bob_emojis.len();
    assert_eq!(
        alice_len, bob_len,
        "Alice's emojis length should be the same as Bob's emojis length"
    );
    for n in 0..alice_len {
        let alice_emoji = &alice_emojis[n];
        let bob_emoji = &bob_emojis[n];
        assert_eq!(
            alice_emoji.symbol(),
            bob_emoji.symbol(),
            "Alice's emoji should be the same as Bob's emoji"
        );
    }

    info!("444444444444444444444444444444444444444444444");
    // Both approve SAS
    alice_prompt_stage.approve().await?;
    bob_prompt_stage.approve().await?;

    Ok(())
}
