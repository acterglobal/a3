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

    let tmp_dir = TempDir::new()?;
    let mut sisko = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "@sisko:ds9.effektio.org".to_string(),
        "sisko".to_string(),
        Some("SISKO_DEV".to_string()),
    )
    .await?;
    let syncer = sisko.start_sync();
    let mut synced = syncer.first_synced_rx().expect("note yet read");
    while synced.next().await != Some(true) {} // let's wait for it to have synced

    let group = sisko
        .get_group("#ops:ds9.effektio.org".to_string())
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
        "> <@sisko:ds9.effektio.org> Hi, everyone\nSorry, it's my bad"
    );

    Ok(())
}
