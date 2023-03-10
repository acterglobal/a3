use anyhow::{bail, Result};
use effektio::{
    api::login_new_client,
    matrix_sdk::ruma::{
        events::{AnyMessageLikeEvent, AnyTimelineEvent, MessageLikeEvent},
        EventId,
    },
};
use futures::stream::StreamExt;
use tempfile::TempDir;

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
        "sisko".to_string(),
        homeserver_name,
        homeserver_url,
        Some("SISKO_DEV".to_string()),
    )
    .await?;
    let syncer = sisko.start_sync();
    let mut synced = syncer.first_synced_rx().expect("note yet read");
    while synced.next().await != Some(true) {} // let's wait for it to have synced

    let group = sisko
        .get_group(format!(
            "#ops:{}",
            option_env!("DEFAULT_HOMESERVER_NAME").unwrap_or("localhost")
        ))
        .await
        .expect("sisko should belong to ops");
    let event_id = group.send_plain_message("Hi, everyone".to_string()).await?;

    let reply_id = group
        .send_text_reply("Sorry, it's my bad".to_string(), event_id, None)
        .await?;

    let reply_id = EventId::parse(reply_id)?;
    let ev = group.event(&reply_id).await?;
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
