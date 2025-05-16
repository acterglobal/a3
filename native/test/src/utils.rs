use acter::{
    api::{Client, Convo, CreateConvoSettingsBuilder, CreateSpaceSettingsBuilder, SyncState},
    testing::ensure_user,
};
use acter_core::templates::Engine;
use anyhow::Result;
use futures::{pin_mut, stream::StreamExt};
use matrix_sdk::config::StoreConfig;
use matrix_sdk_base::ruma::OwnedRoomId;
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

pub async fn accept_all_invites(client: &Client) -> Result<Vec<OwnedRoomId>> {
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

pub async fn random_user(prefix: &str) -> Result<Client> {
    let (user, _uuid) = random_user_with_uuid(prefix).await?;
    Ok(user)
}

async fn random_user_with_uuid(prefix: &str) -> Result<(Client, String)> {
    let uuid = Uuid::new_v4().to_string();
    let user = ensure_user(
        option_env!("DEFAULT_HOMESERVER_URL")
            .unwrap_or("http://localhost:8118")
            .to_owned(),
        option_env!("DEFAULT_HOMESERVER_NAME")
            .unwrap_or("localhost")
            .to_owned(),
        format!("it-{prefix}-{uuid}"),
        option_env!("REGISTRATION_TOKEN").map(ToString::to_string),
        "acter-integration-tests".to_owned(),
        StoreConfig::new("test".to_owned()),
    )
    .await?;
    Ok((user, uuid))
}

pub async fn random_user_with_random_space(prefix: &str) -> Result<(Client, OwnedRoomId)> {
    let (user, uuid) = random_user_with_uuid(prefix).await?;

    let settings = CreateSpaceSettingsBuilder::default()
        .name(format!("it-room-{prefix}-{uuid}"))
        .build()?;
    let room_id = user.create_acter_space(Box::new(settings)).await?;
    Ok((user, room_id))
}

pub async fn random_users_with_random_space(
    prefix: &str,
    user_count: u8,
) -> Result<(Vec<Client>, OwnedRoomId)> {
    assert!(user_count > 0, "User Counts must be more than 0");
    let (main_user, uuid) = random_user_with_uuid(prefix).await?;
    let mut settings = CreateSpaceSettingsBuilder::default();
    settings.name(format!("it-room-{prefix}-{uuid}"));

    let mut users = vec![];
    for _x in 0..user_count {
        let (new_user, _uuid) = random_user_with_uuid(prefix).await?;
        settings.add_invitee(new_user.user_id()?.to_string())?;
        users.push(new_user)
    }

    let room_id = main_user
        .create_acter_space(Box::new(settings.build()?))
        .await?;

    for user in users.iter() {
        loop {
            user.sync_once(Default::default()).await?;
            let room_ids = accept_all_invites(user).await?;
            if room_ids.contains(&room_id) {
                break;
            }
        }
    }
    users.insert(0, main_user);
    Ok((users, room_id))
}

pub async fn random_user_with_random_convo(prefix: &str) -> Result<(Client, OwnedRoomId)> {
    let (user, uuid) = random_user_with_uuid(prefix).await?;

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
            .to_owned(),
        option_env!("DEFAULT_HOMESERVER_NAME")
            .unwrap_or("localhost")
            .to_owned(),
        format!("it-{prefix}-{uuid}"),
        Some(registration_token.to_owned()),
        "acter-integration-tests".to_owned(),
        StoreConfig::new("test".to_owned()),
    )
    .await
}

pub async fn random_users_with_random_convo(
    prefix: &str,
) -> Result<(Client, Client, Client, OwnedRoomId)> {
    let (sisko, _) = random_user_with_uuid(prefix).await?;
    let (kyra, _) = random_user_with_uuid(prefix).await?;
    let (worf, _) = random_user_with_uuid(prefix).await?;

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
        _ => username.to_owned(),
    }
}

pub async fn login_test_user(username: String) -> Result<Client> {
    ensure_user(
        option_env!("DEFAULT_HOMESERVER_URL")
            .unwrap_or("http://localhost:8118")
            .to_owned(),
        option_env!("DEFAULT_HOMESERVER_NAME")
            .unwrap_or("localhost")
            .to_owned(),
        username,
        option_env!("REGISTRATION_TOKEN").map(ToString::to_string),
        "acter-integration-tests".to_owned(),
        StoreConfig::new("login-test-user".to_owned()),
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
            .to_owned(),
        option_env!("DEFAULT_HOMESERVER_NAME")
            .unwrap_or("localhost")
            .to_owned(),
        format!("it-{prefix}-{uuid}"),
        option_env!("REGISTRATION_TOKEN").map(ToString::to_string),
        "acter-integration-tests".to_owned(),
        StoreConfig::new("test".to_owned()),
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

pub async fn random_users_with_random_space_under_template(
    prefix: &str,
    user_count: u8,
    template: &str,
) -> Result<(Vec<Client>, Vec<SyncState>, OwnedRoomId, Engine)> {
    let (mut clients, room_id) = random_users_with_random_space(prefix, user_count).await?;
    let user = clients.first().expect("there are more than one");

    let mut tmpl_engine = user.template_engine(template).await?;
    let inputs = tmpl_engine.requested_inputs();
    if inputs.contains_key("space") {
        tmpl_engine.add_ref("space".to_owned(), "space".to_owned(), room_id.to_string())?;
    }
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

    let sync_states: Vec<SyncState> = clients.iter_mut().map(|c| c.start_sync()).collect();

    Ok((clients, sync_states, room_id, tmpl_engine))
}

pub async fn random_users_with_random_chat_and_space_under_template(
    prefix: &str,
    user_count: u8,
    template: &str,
) -> Result<(
    Vec<Client>,
    Vec<SyncState>,
    OwnedRoomId,
    OwnedRoomId,
    Engine,
)> {
    let (clients, sync_states, space_id, engine) =
        random_users_with_random_space_under_template(prefix, user_count, template).await?;

    let main_user = clients.first().expect("more than one user generated");
    let user_ids = clients
        .iter()
        .skip(1)
        .map(|u| u.user_id().expect("has user id"))
        .collect();

    let uuid = Uuid::new_v4().to_string();
    let settings = CreateConvoSettingsBuilder::default()
        .name(format!("it-room-{prefix}-{uuid}"))
        .invites(user_ids)
        .build()?;
    let room_id = main_user.create_convo(Box::new(settings)).await?;

    Ok((clients, sync_states, space_id, room_id, engine))
}
