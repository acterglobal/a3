use acter::api::{login_new_client, CreateConversationSettingsBuilder};
use anyhow::Result;
use futures::stream::StreamExt;
use log::warn;
use tempfile::TempDir;
use tokio::time::{sleep, Duration};

#[tokio::test]
#[ignore = "test runs forever :("]
async fn sisko_sends_rich_text_to_kyra() -> Result<()> {
    let _ = env_logger::try_init();

    let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME")
        .unwrap_or("localhost")
        .to_string();
    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL")
        .unwrap_or("http://localhost:8118")
        .to_string();

    // initialize sisko's client
    let tmp_dir = TempDir::new()?;
    let mut sisko = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "@sisko".to_string(),
        "sisko".to_string(),
        homeserver_name.clone(),
        homeserver_url.clone(),
        Some("SISKO_DEV".to_string()),
    )
    .await?;
    let sisko_syncer = sisko.start_sync();
    let mut sisko_synced = sisko_syncer.first_synced_rx().expect("not yet read");
    while sisko_synced.next().await != Some(true) {} // let's wait for it to have synced

    // sisko creates room and invites kyra
    let settings = CreateConversationSettingsBuilder::default()
        .invites(vec![format!("@kyra:{homeserver_name}").try_into()?])
        .build()?;
    let sisko_kyra_dm_id = sisko.create_conversation(settings).await?;

    // initialize kyra's client
    let tmp_dir = TempDir::new()?;
    let mut kyra = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "@kyra".to_string(),
        "kyra".to_string(),
        homeserver_name.clone(),
        homeserver_url.clone(),
        Some("KYRA_DEV".to_string()),
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
    let _event_id = convo
        .send_formatted_message("**Hello**".to_string())
        .await?;

    // kyra receives the formatted text message from sisko
    let mut convos_rx = kyra.conversations_rx();
    loop {
        #[allow(clippy::single_match)]
        match convos_rx.next().await {
            Some(convos) => {
                if let Some(convo) = convos.iter().find(|x| *x.room_id() == sisko_kyra_dm_id) {
                    if let Some(msg) = convo.latest_message() {
                        if let Some(event_item) = msg.event_item() {
                            if let Some(text_desc) = event_item.text_desc() {
                                if let Some(formatted) = text_desc.formatted_body() {
                                    let idx = formatted.find("<strong>Hello</strong>");
                                    assert!(idx.is_some(), "formatted body not found");
                                    break;
                                }
                            }
                        }
                    }
                }
            }
            None => {}
        }
    }

    Ok(())
}
