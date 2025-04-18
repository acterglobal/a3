use anyhow::{bail, Result};

use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::{login_test_user, random_user_with_random_convo};

#[tokio::test]
async fn can_recover_and_read_message() -> Result<()> {
    let _ = env_logger::try_init();

    // enable backup on a)
    let (user_id, room_id, backup_pass) = {
        let (mut user, room_id) = random_user_with_random_convo("recovering_message").await?;
        let state_sync = user.start_sync();

        // wait for sync to catch up
        let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
        let fetcher_client = user.clone();
        let target_id = room_id.clone();
        Retry::spawn(retry_strategy.clone(), move || {
            let client = fetcher_client.clone();
            let room_id = target_id.clone();
            async move { client.convo(room_id.to_string()).await }
        })
        .await?;

        let convo = user.convo(room_id.to_string()).await?;
        let timeline = convo.timeline_stream();

        let draft = user.text_plain_draft("Hi, everyone".to_string());
        timeline.send_message(Box::new(draft)).await?;

        let convo_loader = convo.clone();

        let msg = Retry::spawn(retry_strategy, move || {
            let convo = convo_loader.clone();
            async move {
                let Some(msg) = convo.latest_message() else {
                    bail!("No message found")
                };
                Ok(msg)
            }
        })
        .await?;

        assert_eq!(
            msg.event_item()
                .expect("has messsage")
                .message()
                .expect("is message")
                .body(),
            "Hi, everyone"
        );

        let backup_manager = user.backup_manager();
        let backup_pass = backup_manager.enable().await?;
        assert_eq!(backup_manager.state_str(), "enabled");

        // let's wind down
        state_sync.cancel();
        let user_id = user.user_id()?;
        user.logout().await?;

        // pass over for testing
        (user_id, room_id, backup_pass)
    };

    // -- END setup

    // now try to login and recover.

    let mut user = login_test_user(user_id.localpart().to_string()).await?;

    let _state_sync = user.start_sync();

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.convo(room_id.to_string()).await }
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;

    let convo_loader = convo.clone();

    let msg = Retry::spawn(retry_strategy.clone(), move || {
        let convo = convo_loader.clone();
        async move {
            let Some(msg) = convo.latest_message() else {
                bail!("No message found")
            };
            Ok(msg)
        }
    })
    .await?;

    // as expected: we can not read the message
    assert_eq!(
        msg.event_item().expect("exists").event_type(),
        "m.room.encrypted"
    );

    // let's try to enable backuo
    let backup = user.backup_manager();
    backup.recover(backup_pass).await?;
    assert_eq!(backup.state_str(), "enabled");

    // and try again to read the message.

    let convo_loader = convo.clone();
    let msg = Retry::spawn(retry_strategy.clone(), move || {
        let convo = convo_loader.clone();
        async move {
            let Some(msg) = convo.latest_message() else {
                bail!("No message found")
            };
            if msg.event_item().expect("exists").event_type() == "m.room.encrypted" {
                bail!("Message is still encrypted.")
            }
            Ok(msg)
        }
    })
    .await?;

    // as expected: we CAN read the message
    assert_eq!(
        msg.event_item()
            .expect("has messsage")
            .message()
            .expect("is message")
            .body(),
        "Hi, everyone" // WE CAN READ IT AGAIN
    );

    Ok(())
}

#[tokio::test]
async fn key_is_kept_and_reset() -> Result<()> {
    let _ = env_logger::try_init();

    // enabled backup stores the key
    let (mut user, _room_id) = random_user_with_random_convo("recovering_message").await?;
    let _state_sync = user.start_sync();

    let backup_manager = user.backup_manager();
    let backup_pass = backup_manager.enable().await?;
    assert_eq!(backup_manager.state_str(), "enabled");
    assert_eq!(
        backup_manager.stored_enc_key().await?.text(),
        Some(backup_pass)
    );
    assert_ne!(backup_manager.stored_enc_key_when().await?, 0);

    backup_manager.disable().await?;
    assert!(backup_manager.stored_enc_key().await?.text().is_none());
    assert_eq!(backup_manager.stored_enc_key_when().await?, 0);
    assert_eq!(backup_manager.state_str(), "disabled");

    let backup_pass = backup_manager.enable().await?;
    assert_eq!(backup_manager.state_str(), "enabled");
    assert_eq!(
        backup_manager
            .stored_enc_key()
            .await
            .unwrap()
            .text()
            .unwrap(),
        backup_pass
    );
    assert_ne!(backup_manager.stored_enc_key_when().await?, 0);

    let new_pass = backup_manager.reset().await?;
    assert_eq!(backup_manager.state_str(), "enabled");
    assert_eq!(
        backup_manager.stored_enc_key().await?.text(),
        Some(new_pass)
    );
    assert_ne!(backup_manager.stored_enc_key_when().await?, 0);

    backup_manager.destroy_stored_enc_key().await?;
    assert!(backup_manager.stored_enc_key().await?.text().is_none());
    assert_eq!(backup_manager.stored_enc_key_when().await?, 0);

    Ok(())
}
