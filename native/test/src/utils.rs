use acter::{
    matrix_sdk::config::StoreConfig, ruma_common::OwnedRoomId, testing::ensure_user, Client,
    CreateConvoSettingsBuilder, CreateSpaceSettingsBuilder, SyncState,
};
use acter_core::templates::Engine;
use anyhow::Result;
use futures::{pin_mut, stream::StreamExt};
use tracing::trace;
use uuid::Uuid;

pub async fn random_user_with_random_convo(prefix: &str) -> Result<(Client, OwnedRoomId)> {
    let uuid = Uuid::new_v4().to_string();
    let user = ensure_user(
        option_env!("DEFAULT_HOMESERVER_URL")
            .unwrap_or("http://localhost:8118")
            .to_string(),
        option_env!("DEFAULT_HOMESERVER_NAME")
            .unwrap_or("localhost")
            .to_string(),
        format!("it-{prefix}-{uuid}"),
        option_env!("REGISTRATION_TOKEN").map(ToString::to_string),
        "acter-integration-tests".to_owned(),
        StoreConfig::default(),
    )
    .await?;

    let settings = CreateConvoSettingsBuilder::default()
        .name(format!("it-room-{prefix}-{uuid}"))
        .build()?;
    let room_id = user.create_convo(Box::new(settings)).await?;
    Ok((user, room_id))
}

pub async fn random_user_with_random_space(prefix: &str) -> Result<(Client, OwnedRoomId)> {
    let uuid = Uuid::new_v4().to_string();
    let user = ensure_user(
        option_env!("DEFAULT_HOMESERVER_URL")
            .unwrap_or("http://localhost:8118")
            .to_string(),
        option_env!("DEFAULT_HOMESERVER_NAME")
            .unwrap_or("localhost")
            .to_string(),
        format!("it-{prefix}-{uuid}"),
        option_env!("REGISTRATION_TOKEN").map(ToString::to_string),
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

pub fn default_user_password(username: &str) -> String {
    match option_env!("REGISTRATION_TOKEN") {
        Some(t) => format!("{t}:{username}"),
        _ => username.to_string(),
    }
}

pub async fn login_test_user(username: String) -> Result<Client> {
    ensure_user(
        option_env!("DEFAULT_HOMESERVER_URL")
            .unwrap_or("http://localhost:8118")
            .to_string(),
        option_env!("DEFAULT_HOMESERVER_NAME")
            .unwrap_or("localhost")
            .to_string(),
        username,
        option_env!("REGISTRATION_TOKEN").map(ToString::to_string),
        "acter-integration-tests".to_owned(),
        StoreConfig::default(),
    )
    .await
}

pub async fn random_user_with_template(
    prefix: &str,
    template: &str,
) -> Result<(Client, SyncState, Engine)> {
    let uuid = Uuid::new_v4().to_string();
    let mut user = ensure_user(
        option_env!("DEFAULT_HOMESERVER_URL")
            .unwrap_or("http://localhost:8118")
            .to_string(),
        option_env!("DEFAULT_HOMESERVER_NAME")
            .unwrap_or("localhost")
            .to_string(),
        format!("it-{prefix}-{uuid}"),
        option_env!("REGISTRATION_TOKEN").map(ToString::to_string),
        "acter-integration-tests".to_owned(),
        StoreConfig::default(),
    )
    .await?;

    let sync_state = user.start_sync();

    let tmpl_engine = user.template_engine(template).await?;
    let exec_stream = tmpl_engine.execute()?;
    trace!(
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
