use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user;
use anyhow::{bail, Result};
use matrix_sdk_base::ruma::{api::client::room::create_room, assign, room::RoomType, serde::Raw};

#[tokio::test]
async fn upgrade_flow() -> Result<()> {
    let _ = env_logger::try_init();
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);

    let mut user = random_user("upgrade").await?;
    let _sync_state = user.start_sync();

    let spaces = user.spaces().await?;
    assert_eq!(spaces.len(), 0);

    let creation = assign!(create_room::v3::CreationContent::new(), {
        room_type: Some(RoomType::Space),
    });

    let req = assign!(create_room::v3::Request::new(), {
        creation_content: Some(Raw::new(&creation)?), // create as space
    });
    let _non_acter_space = user.create_room(req).await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if user.spaces().await?.len() != 1 {
            bail!("not all spaces found");
        }
        Ok(())
    })
    .await?;

    let mut spaces = user.spaces().await?;

    assert_eq!(spaces.len(), 1);
    let space = spaces.pop().expect("at least a space should exist");

    assert!(!space.is_acter_space().await?);
    let member = space.get_my_membership().await?;
    assert!(member.can_string("CanUpgradeToActerSpace".to_owned())); // but we can upgrade

    // let's upgrade

    space.set_acter_space_states().await?;

    let space = Retry::spawn(retry_strategy, || async {
        let spaces = user.spaces().await?;
        let Some(space) = spaces.first() else {
            bail!("not all spaces found");
        };
        if !space.is_acter_space().await? {
            bail!("not converted")
        }
        Ok(space.clone())
    })
    .await?;

    assert!(space.is_acter_space().await?);
    let member = space.get_my_membership().await?;
    assert!(!member.can_string("CanUpgradeToActerSpace".to_owned())); // we can't upgrade

    // but we can change settings
    assert!(member.can_string("CanChangeAppSettings".to_owned())); // we can't upgrade

    Ok(())
}
