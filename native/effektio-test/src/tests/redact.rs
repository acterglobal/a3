use anyhow::Result;
use effektio::{
    api::login_new_client,
    matrix_sdk::ruma::{
        events::{AnyMessageLikeEvent, AnyTimelineEvent},
        EventId,
    },
};
use futures::stream::StreamExt;
use tempfile::TempDir;

#[tokio::test]
async fn sisko_redacts_message() -> Result<()> {
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
    println!("event id: {event_id:?}");

    let redact_id = group
        .redact_message(event_id.clone(), Some("redact-test".to_string()), None)
        .await?;

    let redact_id = EventId::parse(redact_id)?;
    let ev = group.event(&redact_id).await?;
    println!("redact: {ev:?}");

    let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomRedaction(r))) = ev.event.deserialize() else {
        panic!("not the proper room event");
    };

    let Some(e) = r.as_original() else {
        panic!("This should be m.room.redaction event");

    };

    assert_eq!(e.redacts.to_string(), event_id);
    Ok(())
}
