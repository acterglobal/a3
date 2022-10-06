use anyhow::Result;
use effektio::{login_new_client, matrix_sdk::ruma::user_id};
use std::time::Duration;
use tempfile::TempDir;
use tokio::time::sleep;

#[tokio::test]
async fn load_pending_invitation() -> Result<()> {
    let _ = env_logger::try_init();

    let tmp_dir = TempDir::new()?;
    let sisko = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@sisko:ds9.effektio.org".to_owned(),
        "sisko".to_owned(),
    )
    .await?;
    let sisko_syncer = sisko.start_sync();

    let tmp_dir = TempDir::new()?;
    let kyra = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@kyra:ds9.effektio.org".to_owned(),
        "kyra".to_owned(),
    )
    .await?;
    let kyra_syncer = kyra.start_sync();

    sleep(Duration::from_secs(3)).await;

    // let room_id = sisko.create_room().await?;
    // println!("created room id: {}", room_id);

    // sleep(Duration::from_secs(3)).await;

    // let room = sisko.get_joined_room(room_id.as_str().try_into().unwrap()).unwrap();
    // let kyra_id = user_id!("@kyra:ds9.effektio.org");
    // room.invite_user_by_id(kyra_id).await?;

    // sleep(Duration::from_secs(3)).await;

    let mut event_rx = kyra.invitation_event_rx().unwrap();
    loop {
        match event_rx.try_next() {
            Ok(Some(event)) => {
                println!("received: {:?}", event);
                // break;
            }
            Ok(None) => {
                println!("received: none");
            }
            Err(e) => {}
        }
    }

    sleep(Duration::from_secs(3)).await;

    Ok(())
}
