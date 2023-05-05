use acter::{matrix_sdk::config::StoreConfig, testing::ensure_user, CreateSpaceSettingsBuilder};
use acter_core::{ruma::OwnedRoomId, templates::Engine};
use anyhow::Result;
use futures::{pin_mut, StreamExt};

pub async fn random_user_with_random_space(prefix: &str) -> Result<(acter::Client, OwnedRoomId)> {
    let uuid = uuid::Uuid::new_v4().to_string();
    let user = ensure_user(
        option_env!("DEFAULT_HOMESERVER_URL").unwrap_or("http://localhost:8118"),
        format!("it-{prefix}-{uuid}"),
        "acter-integration-tests".to_owned(),
        StoreConfig::default(),
    )
    .await?;

    let settings = CreateSpaceSettingsBuilder::default()
        .name(format!("it-room-{prefix}-{uuid}"))
        .build()?;
    let room_id = user.create_acter_space(Box::new(settings)).await?;
    Ok((user, room_id))
}

pub async fn random_user_with_template(
    prefix: &str,
    template: &str,
) -> Result<(acter::Client, acter::SyncState, Engine)> {
    let uuid = uuid::Uuid::new_v4().to_string();
    let mut user = ensure_user(
        option_env!("DEFAULT_HOMESERVER_URL").unwrap_or("http://localhost:8118"),
        format!("it-{prefix}-{uuid}"),
        "acter-integration-tests".to_owned(),
        StoreConfig::default(),
    )
    .await?;

    let sync_state = user.start_sync();

    let tmpl_engine = user.template_engine(template).await?;
    let exec_stream = tmpl_engine.execute()?;
    tracing::trace!(
        total = exec_stream.total(),
        user_id = ?user.user_id()?,
        "executing template"
    );
    pin_mut!(exec_stream);
    while let Some(i) = exec_stream.next().await {
        i?
    }
    Ok((user, sync_state, tmpl_engine))
}
