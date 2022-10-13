use anyhow::Result;
use effektio::api::{login_new_client, CreateConversationSettingsBuilder};
use futures::stream::StreamExt;
use log::warn;
use tempfile::TempDir;
use tokio::time::{sleep, Duration};

#[tokio::test]
async fn sisko_sends_rich_text_to_kyra() -> Result<()> {
    let _ = env_logger::try_init();

    // initialize sisko's client
    let tmp_dir = TempDir::new()?;
    let sisko = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@sisko:ds9.effektio.org".to_owned(),
        "sisko".to_owned(),
    )
    .await?;
    let sisko_syncer = sisko.start_sync();
    let mut sisko_synced = sisko_syncer.first_synced_rx().expect("note yet read");
    while sisko_synced.next().await != Some(true) {} // let's wait for it to have synced

    // sisko creates room and invites kyra
    let sisko_kyra_dm_id = sisko
        .create_conversation(
            CreateConversationSettingsBuilder::default()
                .invites(vec!["@kyra:ds9.effektio.org".to_owned().try_into()?])
                .build()?,
        )
        .await?;

    // initialize kyra's client
    let tmp_dir = TempDir::new()?;
    let kyra = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@kyra:ds9.effektio.org".to_owned(),
        "kyra".to_owned(),
    )
    .await?;
    let kyra_syncer = kyra.start_sync();
    let mut first_synced = kyra_syncer.first_synced_rx().expect("not yet read");
    while first_synced.next().await != Some(true) {} // let's wait for it to have synced

    // kyra accepts invitation from sisko
    let invited = kyra.get_invited_room(&sisko_kyra_dm_id).unwrap();
    let mut delay = 2;
    while let Err(e) = invited.accept_invitation().await {
        sleep(Duration::from_secs(delay)).await;
        delay *= 2;
        if delay > 3600 {
            warn!("Can't join room {} ({:?})", invited.room_id(), e);
            break;
        }
    }

    // sisko sends the formatted text message to kyra
    let convo = sisko.conversation(sisko_kyra_dm_id.to_string()).await?;
    let event_id = convo.send_formatted_message("**Hello**".to_owned()).await?;

    // kyra receives the formatted text message from sisko
    let mut convos_rx = kyra.conversations_rx();
    loop {
        match convos_rx.next().await {
            Some(convos) => {
                if let Some(convo) = convos
                    .iter()
                    .find(|x| x.room_id().to_owned() == sisko_kyra_dm_id)
                {
                    if let Some(msg) = convo.latest_message() {
                        if let Some(formatted) = msg.formatted_body() {
                            let idx = formatted.find("<strong>Hello</strong>");
                            assert!(idx.is_some(), "formatted body not found");
                            break;
                        }
                    }
                }
            }
            None => {}
        }
    }

    Ok(())
}
