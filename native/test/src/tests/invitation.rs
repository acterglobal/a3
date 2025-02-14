use anyhow::Result;
use futures::{pin_mut, stream::StreamExt};
use std::time::Duration;
use tokio::time::sleep;

use crate::utils::random_user;

#[tokio::test]
async fn load_pending_invitation() -> Result<()> {
    let _ = env_logger::try_init();

    let mut sisko = random_user("loading_pending_invitation_sisko").await?;
    let _sisko_syncer = sisko.start_sync().await?;

    let mut kyra = random_user("loading_pending_invitation_kyra").await?;
    let _kyra_syncer = kyra.start_sync().await?;

    sleep(Duration::from_secs(3)).await;

    // sisko creates room and invites kyra
    // let settings = acter::api::CreateConvoSettingsBuilder::default().build()?;
    // let room_id = sisko.create_convo(settings).await?;
    // println!("created room id: {}", room_id);

    // sleep(Duration::from_secs(3)).await;

    // let room = sisko.get_joined_room(room_id.as_str().try_into()?)?;
    // let kyra_id = matrix_sdk_base::ruma::user_id!("@kyra");
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
