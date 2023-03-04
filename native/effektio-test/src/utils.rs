use anyhow::Result;
use effektio::{matrix_sdk::config::StoreConfig, testing::ensure_user, CreateGroupSettingsBuilder};
use effektio_core::ruma::OwnedRoomId;

pub async fn random_user_with_random_space(
    prefix: &str,
) -> Result<(effektio::Client, OwnedRoomId)> {
    let uuid = uuid::Uuid::new_v4().to_string();
    let user = ensure_user(
        option_env!("DEFAULT_HOMESERVER_URL").unwrap_or("http://localhost:8118"),
        format!("it-{prefix}-{uuid}"),
        "effektio-integration-tests".to_owned(),
        StoreConfig::default(),
    )
    .await?;

    let settings = Box::new(
        CreateGroupSettingsBuilder::default()
            .name(format!("it-room-{prefix}-{uuid}"))
            .build()?,
    );
    let room_id = user.create_effektio_group(settings).await?;
    Ok((user, room_id))
}
