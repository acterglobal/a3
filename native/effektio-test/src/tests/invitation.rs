use anyhow::Result;
use effektio::api::login_new_client;
use futures::{pin_mut, StreamExt};
use std::time::Duration;
use tempfile::TempDir;
use tokio::time::sleep;

#[tokio::test]
async fn load_pending_invitation() -> Result<()> {
    let _ = env_logger::try_init();

    let tmp_dir = TempDir::new()?;
    let mut sisko = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "@sisko:ds9.effektio.org".to_string(),
        "sisko".to_string(),
        Some("SISKO_DEV".to_string()),
    )
    .await?;
    let _sisko_syncer = sisko.start_sync();

    let tmp_dir = TempDir::new()?;
    let mut kyra = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "@kyra:ds9.effektio.org".to_string(),
        "kyra".to_string(),
        Some("KYRA_DEV".to_string()),
    )
    .await?;
    let _kyra_syncer = kyra.start_sync();

    sleep(Duration::from_secs(3)).await;

    // sisko creates room and invites kyra
    // let settings = effektio::api::CreateConversationSettingsBuilder::default().build()?;
    // let room_id = sisko.create_conversation(settings).await?;
    // println!("created room id: {}", room_id);

    // sleep(Duration::from_secs(3)).await;

    // let room = sisko.get_joined_room(room_id.as_str().try_into()?)?;
    // let kyra_id = effektio::matrix_sdk::ruma::user_id!("@kyra:ds9.effektio.org");
    // room.invite_user_by_id(kyra_id).await?;

    // sleep(Duration::from_secs(3)).await;

    let receiver = kyra.invitations_rx();
    pin_mut!(receiver);
    loop {
        match receiver.next().await {
            Some(invitations) => {
                println!("received: {invitations:?}");
                break;
            }
            None => {
                println!("received: none");
            }
        }
    }

    sleep(Duration::from_secs(3)).await;

    Ok(())
}
