use acter::{
    api::login_new_client,
    matrix_sdk::ruma::events::{AnyMessageLikeEvent, AnyTimelineEvent, MessageLikeEvent},
};
use anyhow::{bail, Result};
use futures::stream::StreamExt;
use tempfile::TempDir;

use crate::utils::default_user_password;

#[tokio::test]
async fn sisko_replies_message() -> Result<()> {
    let _ = env_logger::try_init();
    let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME")
        .unwrap_or("localhost")
        .to_string();
    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL")
        .unwrap_or("http://localhost:8118")
        .to_string();

    let tmp_dir = TempDir::new()?;
    let mut sisko = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "@sisko".to_string(),
        default_user_password("sisko"),
        homeserver_name,
        homeserver_url,
        Some("SISKO_DEV".to_string()),
    )
    .await?;
    let syncer = sisko.start_sync();
    let mut synced = syncer.first_synced_rx().expect("not yet read");
    while synced.next().await != Some(true) {} // let's wait for it to have synced

    let space = sisko
        .get_space(format!(
            "#ops:{}",
            option_env!("DEFAULT_HOMESERVER_NAME").unwrap_or("localhost")
        ))
        .await
        .expect("sisko should belong to ops");
    let event_id = space.send_plain_message("Hi, everyone".to_string()).await?;

    let reply_id = space
        .send_text_reply("Sorry, it's my bad".to_string(), event_id.to_string(), None)
        .await?;

    let ev = space.event(&reply_id).await?;
    println!("reply: {ev:?}");

    let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(MessageLikeEvent::Original(m)))) = ev.event.deserialize() else {
        bail!("Could not deserialize event");
    };

    assert_eq!(
        m.content.body(),
        format!(
            "> <@sisko:{}> Hi, everyone\nSorry, it's my bad",
            option_env!("DEFAULT_HOMESERVER_NAME").unwrap_or("localhost")
        )
    );

    Ok(())
}
