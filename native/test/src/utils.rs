use acter::{
    matrix_sdk::{config::StoreConfig, ruma::OwnedRoomId},
    testing::ensure_user,
    Client, CreateSpaceSettingsBuilder, SyncState,
};
use acter_core::templates::Engine;
use anyhow::Result;
use futures::{pin_mut, StreamExt};
use tracing::trace;

pub async fn random_user_with_random_space(prefix: &str) -> Result<(Client, OwnedRoomId)> {
    let uuid = uuid::Uuid::new_v4().to_string();
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

pub async fn random_users_with_random_space(prefix: &str) -> Result<(Client, Client, OwnedRoomId)> {
    let uuid = uuid::Uuid::new_v4().to_string();
    let alice = ensure_user(
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

    let uuid = uuid::Uuid::new_v4().to_string();
    let bob = ensure_user(
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
    let room_id = alice.create_acter_space(Box::new(settings)).await?;

    let room = alice.get_joined_room(&room_id).unwrap();
    let user_id = bob.user_id()?;
    room.invite_user_by_id(&user_id).await?;

    bob.sync_once(Default::default()).await?;
    for invited in bob.invited_rooms().iter() {
        invited.accept_invitation().await?;
    }

    Ok((alice, bob, room_id))
}

pub fn default_user_password(username: &str) -> String {
    match option_env!("REGISTRATION_TOKEN") {
        Some(t) => format!("{t}:{username}"),
        _ => username.to_string(),
    }
}

pub async fn random_user_with_template(
    prefix: &str,
    template: &str,
) -> Result<(Client, SyncState, Engine)> {
    let uuid = uuid::Uuid::new_v4().to_string();
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
