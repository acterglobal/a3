use anyhow::Result;
use effektio::api::login_new_client;
use futures::{pin_mut, StreamExt};
use tempfile::TempDir;

#[tokio::test]
async fn kyra_detects_sisko_typing() -> Result<()> {
    let _ = env_logger::try_init();

    let tmp_dir = TempDir::new()?;
    let sisko = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@sisko:ds9.effektio.org".to_owned(),
        "sisko".to_owned(),
    )
    .await?;
    let sisko_syncer = sisko.start_sync();
    let mut first_synced = sisko_syncer.get_first_synced_rx().expect("not yet read");
    while first_synced.next().await != Some(true) {} // let's wait for it to have synced
    let sisko_group = sisko
        .get_group("#ops:ds9.effektio.org".to_owned())
        .await
        .expect("sisko should belong to ops");

    let tmp_dir = TempDir::new()?;
    let kyra = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@kyra:ds9.effektio.org".to_owned(),
        "kyra".to_owned(),
    )
    .await?;
    let kyra_syncer = kyra.start_sync();
    println!("kyra started sync");
    let kyra_conv = kyra.conversation("#ops:ds9.effektio.org".to_owned()).await?;
    println!("kyra conversation was got");
    let event_rx0 = kyra_conv.typing_updates();
    pin_mut!(event_rx0);
    let event_rx1 = kyra_conv.typing_updates();
    pin_mut!(event_rx1);

    loop {
        match event_rx1.next().await {
            Some(event) => {
                println!("received: {:?}", event);
                break;
            }
            None => {
                // println!("receiver empty");
            }
        }
    }

    for n in 0..100 {
        println!("index: {}", n);
        let sent = sisko_group.typing_notice(true).await?;
        println!("sent: {:?}", sent);

        loop {
            match event_rx1.next().await {
                Some(event) => {
                    println!("received: {:?}", event);
                    break;
                }
                None => {
                    // println!("receiver empty");
                }
            }
        }
    }

    Ok(())
}
