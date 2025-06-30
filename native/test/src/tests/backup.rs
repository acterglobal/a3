use anyhow::{bail, Result};

use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::{default_user_password, login_test_user, random_user_with_random_convo};

#[tokio::test]
async fn can_recover_and_read_message() -> Result<()> {
    let _ = env_logger::try_init();

    // enable backup on a)
    let body = "Hi, everyone";
    let (user_id, room_id, backup_pass) = {
        let (mut user, room_id) = random_user_with_random_convo("recovering_message").await?;
        let state_sync = user.start_sync().await?;
        state_sync.await_has_synced_history().await?;

        // wait for sync to catch up
        let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
        Retry::spawn(retry_strategy.clone(), || async {
            user.convo(room_id.to_string()).await
        })
        .await?;

        let convo = user.convo(room_id.to_string()).await?;
        let timeline = convo.timeline_stream().await?;

        let draft = user.text_plain_draft(body.to_owned());
        timeline.send_message(Box::new(draft)).await?;

        let convo_loader = convo.clone();

        let msg = Retry::spawn(retry_strategy, move || {
            let convo = convo_loader.clone();
            async move {
                let latest_message = convo.latest_message().await?;
                let Some(msg) = latest_message.data() else {
                    bail!("No message found")
                };
                Ok(msg)
            }
        })
        .await?;

        assert_eq!(
            msg.event_item()
                .expect("has messsage")
                .msg_content()
                .expect("is message")
                .body(),
            body
        );

        let backup_manager = user.backup_manager();
        let backup_pass = backup_manager.enable().await?;
        assert_eq!(backup_manager.state_str(), "enabled");

        // let’s wind down
        state_sync.cancel();
        let user_id = user.user_id()?;
        user.logout().await?;

        // pass over for testing
        (user_id, room_id, backup_pass)
    };

    // -- END setup

    // now try to login and recover.

    let mut user = login_test_user(user_id.localpart().to_owned()).await?;

    let _state_sync = user.start_sync().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        user.convo(room_id.to_string()).await
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;

    let convo_loader = convo.clone();

    let msg = Retry::spawn(retry_strategy.clone(), move || {
        let convo = convo_loader.clone();
        async move {
            let latest_message = convo.latest_message().await?;
            let Some(msg) = latest_message.data() else {
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

    // let’s try to enable backuo
    let backup = user.backup_manager();
    backup.recover(backup_pass).await?;
    assert_eq!(backup.state_str(), "enabled");

    // and try again to read the message.

    let convo_loader = convo.clone();
    let msg = Retry::spawn(retry_strategy, move || {
        let convo = convo_loader.clone();
        async move {
            let latest_message = convo.latest_message().await?;
            let Some(msg) = latest_message.data() else {
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
            .msg_content()
            .expect("is message")
            .body(),
        body // WE CAN READ IT AGAIN
    );

    Ok(())
}

#[tokio::test]
async fn key_is_kept_and_reset() -> Result<()> {
    let _ = env_logger::try_init();

    // enabled backup stores the key
    let (mut user, _room_id) = random_user_with_random_convo("recovering_message").await?;
    let _state_sync = user.start_sync().await?;

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
        backup_manager.stored_enc_key().await?.text(),
        Some(backup_pass)
    );
    assert_ne!(backup_manager.stored_enc_key_when().await?, 0);

    let new_pass = backup_manager.reset_key().await?;
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

#[tokio::test]
async fn identiy_reset_and_fresh_key() -> Result<()> {
    let _ = env_logger::try_init();

    // enabled backup stores the key
    let (mut user, _room_id) = random_user_with_random_convo("recovering_message").await?;
    let _state_sync = user.start_sync().await?;

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
        backup_manager.stored_enc_key().await?.text(),
        Some(backup_pass)
    );
    assert_ne!(backup_manager.stored_enc_key_when().await?, 0);

    let new_pass = backup_manager
        .reset_identity(default_user_password(user.user_id()?.localpart()))
        .await?;
    assert_eq!(
        backup_manager.stored_enc_key().await?.text(),
        Some(new_pass)
    );
    assert_eq!(backup_manager.state_str(), "enabled");
    assert_ne!(backup_manager.stored_enc_key_when().await?, 0);

    backup_manager.destroy_stored_enc_key().await?;
    assert!(backup_manager.stored_enc_key().await?.text().is_none());
    assert_eq!(backup_manager.stored_enc_key_when().await?, 0);

    Ok(())
}
