use acter::{
    api::login_new_client,
    matrix_sdk::ruma::{
        events::{AnyMessageLikeEvent, AnyTimelineEvent, MessageLikeEvent},
        OwnedRoomAliasId,
    },
};
use anyhow::{bail, Result};
use futures::stream::StreamExt;
use tempfile::TempDir;

use crate::utils::default_user_password;

#[tokio::test]
async fn sisko_reads_kyra_reply() -> Result<()> {
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
        homeserver_name.clone(),
        homeserver_url.clone(),
        Some("SISKO_DEV".to_string()),
    )
    .await?;
    let syncer = sisko.start_sync();
    let mut synced = syncer.first_synced_rx();
    while synced.next().await != Some(true) {} // let's wait for it to have synced

    let tmp_dir = TempDir::new()?;
    let mut kyra = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "@kyra".to_string(),
        default_user_password("kyra"),
        homeserver_name.clone(),
        homeserver_url,
        Some("KYRA_DEV".to_string()),
    )
    .await?;
    let syncer = kyra.start_sync();
    let mut synced = syncer.first_synced_rx();
    while synced.next().await != Some(true) {} // let's wait for it to have synced

    let Ok(alias_id) = OwnedRoomAliasId::try_from(format!("#ops:{homeserver_name}")) else {
        bail!("Invalid room alias id");
    };
    let response = sisko.resolve_room_alias(&alias_id).await?;
    let sisko_space = sisko
        .get_space(response.room_id.to_string())
        .await
        .expect("sisko should belong to ops");
    let event_id = sisko_space
        .send_plain_message("Hi, everyone".to_string())
        .await?;

    let response = kyra.resolve_room_alias(&alias_id).await?;
    let kyra_space = kyra
        .get_space(response.room_id.to_string())
        .await
        .expect("kyra should belong to ops");
    let reply_id = kyra_space
        .send_text_reply("Sorry, it's my bad".to_string(), event_id.to_string(), None)
        .await?;

    let ev = sisko_space.event(&reply_id).await?;
    println!("reply: {ev:?}");

    let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(MessageLikeEvent::Original(m)))) = ev.event.deserialize() else {
        bail!("Could not deserialize event");
    };

    assert_eq!(
        m.content.body(),
        format!(
            "> <@sisko:{}> Hi, everyone\n\nSorry, it's my bad",
            homeserver_name,
        )
    );

    Ok(())
}
