use anyhow::Result;
use effektio::api::login_new_client;
use effektio::CreateConversationSettingsBuilder;
use futures::stream::StreamExt;
use log::info;
use tempfile::TempDir;

#[tokio::test]
async fn kyra_detects_latest_message_in_realtime() -> Result<()> {
    let _ = env_logger::try_init();

    let tmp_dir = TempDir::new()?;
    let sisko = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@sisko:ds9.effektio.org".to_owned(),
        "sisko".to_owned(),
    )
    .await?;

    let sisko_kyra_dm_id = sisko
        .create_conversation(
            CreateConversationSettingsBuilder::default()
                .invites(vec!["@kyra:ds9.effektio.org".to_owned().try_into()?])
                .build()?,
        )
        .await?;
    let sisko_syncer = sisko.start_sync();
    let mut sisko_synced = sisko_syncer.get_first_synced_rx().expect("not yet read");
    while sisko_synced.next().await != Some(true) {} // let's wait for it to have synced
    info!("sisko synced");

    let dm_convo = sisko.conversation(sisko_kyra_dm_id.to_string()).await?;

    let tmp_dir = TempDir::new()?;
    let kyra = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@kyra:ds9.effektio.org".to_owned(),
        "kyra".to_owned(),
    )
    .await?;
    let kyra_syncer = kyra.start_sync();
    let mut kyra_synced = kyra_syncer.get_first_synced_rx().expect("not yet read");
    while kyra_synced.next().await != Some(true) {} // let's wait for it to have synced
    info!("kyra synced");

    let sisko_group = sisko
        .get_group("#ops:ds9.effektio.org".to_owned())
        .await
        .expect("sisko should belong to ops");
    info!("sisko got group");
    sisko_group
        .send_plain_message("Hi, everyone".to_owned())
        .await?;
    info!("sisko sent plain message");

    // let mut kyra_convos_rx = kyra.conversations_rx();
    // info!("conversations receiver ready");
    // loop {
    //     match kyra_convos_rx.next().await {
    //         Some(convos) => {
    //             info!("conversations received");
    //             let msg = convos[0].latest_message();
    //             assert!(msg.is_some(), "The changed conversation should be moved to 1st item");
    //             assert_eq!(msg.unwrap().body(), "Hi, everyone".to_owned(), "it should be the same as msg sent by sisko");
    //             break;
    //         }
    //         None => {}
    //     }
    // }

    Ok(())
}
