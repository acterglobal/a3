use acter::{
    matrix_sdk::config::StoreConfig, ruma_common::OwnedRoomId, testing::ensure_user, Client, Convo,
    CreateConvoSettingsBuilder, CreateSpaceSettingsBuilder, SyncState,
};
use acter_core::templates::Engine;
use anyhow::Result;
use futures::{pin_mut, stream::StreamExt};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};
use tracing::{info, trace};
use uuid::Uuid;

pub async fn wait_for_convo_joined(client: Client, convo_id: OwnedRoomId) -> Result<Convo> {
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, move || {
        let client = client.clone();
        let convo_id_str = convo_id.to_string();
        async move { client.convo(convo_id_str).await }
    })
    .await
}

pub async fn accept_all_invites(client: Client) -> Result<Vec<OwnedRoomId>> {
    let user_id = client.user_id()?;
    let mut rooms = vec![];
    for invited in client.invited_rooms().iter() {
        let room_id = invited.room_id();
        info!(" - {user_id} accepting invite to {room_id}",);
        rooms.push(room_id.to_owned());
        invited.join().await?;
    }
    Ok(rooms)
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

pub async fn random_user_under_token(prefix: &str, registration_token: &str) -> Result<Client> {
    let uuid = Uuid::new_v4().to_string();
    ensure_user(
        option_env!("DEFAULT_HOMESERVER_URL")
            .unwrap_or("http://localhost:8118")
            .to_string(),
        option_env!("DEFAULT_HOMESERVER_NAME")
            .unwrap_or("localhost")
            .to_string(),
        format!("it-{prefix}-{uuid}"),
        Some(registration_token.to_owned()),
        "acter-integration-tests".to_owned(),
        StoreConfig::default(),
    )
    .await
}

pub async fn random_users_with_random_convo(
    prefix: &str,
) -> Result<(Client, Client, Client, OwnedRoomId)> {
    let uuid = Uuid::new_v4().to_string();
    let sisko = ensure_user(
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

    let uuid = Uuid::new_v4().to_string();
    let kyra = ensure_user(
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

    let uuid = Uuid::new_v4().to_string();
    let worf = ensure_user(
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

    let uuid = Uuid::new_v4().to_string();
    let settings = CreateConvoSettingsBuilder::default()
        .name(format!("it-room-{prefix}-{uuid}"))
        .invites(vec![kyra.user_id()?, worf.user_id()?])
        .build()?;
    let room_id = sisko.create_convo(Box::new(settings)).await?;

    Ok((sisko, kyra, worf, room_id))
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
