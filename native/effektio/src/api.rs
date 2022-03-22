use crate::platform;
use anyhow::{bail, Result};
use derive_builder::Builder;
use effektio_core::ruma::api::client::account::register;
use effektio_core::RestoreToken;
use futures::{stream, Stream};
use lazy_static::lazy_static;
pub use matrix_sdk::ruma::{DeviceId, MxcUri, RoomId, ServerName, UserId};
use matrix_sdk::{
    media::{MediaFormat, MediaRequest, MediaType},
    room::Room as MatrixRoom,
    Client as MatrixClient, LoopCtrl, Session,
};
use parking_lot::RwLock;
use std::sync::Arc;
use tokio::runtime;
use url::Url;

lazy_static! {
    static ref RUNTIME: runtime::Runtime =
        runtime::Runtime::new().expect("Can't start Tokio runtime");
}

ffi_gen_macro::ffi_gen!("native/effektio/api.rsh");

#[derive(Default, Builder, Debug)]
pub struct ClientState {
    #[builder(default)]
    pub is_guest: bool,
    #[builder(default)]
    pub has_first_synced: bool,
    #[builder(default)]
    pub is_syncing: bool,
    #[builder(default)]
    pub should_stop_syncing: bool,
}

#[derive(Clone)]
pub struct Client {
    client: MatrixClient,
    state: Arc<RwLock<ClientState>>,
}

pub struct Room {
    room: MatrixRoom,
}

pub struct RoomMember {
    member: matrix_sdk::RoomMember,
}

impl Room {
    async fn display_name(&self) -> Result<String> {
        let r = self.room.clone();
        RUNTIME
            .spawn(async move { Ok(r.display_name().await?) })
            .await?
    }

    pub async fn avatar(&self) -> Result<api::FfiBuffer<u8>> {
        let r = self.room.clone();
        RUNTIME
            .spawn(async move {
                Ok(api::FfiBuffer::new(
                    r.avatar(MediaFormat::File).await?.expect("No avatar"),
                ))
            })
            .await?
    }

    pub async fn active_members(&self) -> Result<Vec<RoomMember>> {
        let r = self.room.clone();
        RUNTIME
            .spawn(async move {
                Ok(r.active_members()
                    .await
                    .expect("No members")
                    .into_iter()
                    .map(|member| RoomMember { member })
                    .collect())
            })
            .await?
    }

    pub async fn active_members_no_sync(&self) -> Result<Vec<RoomMember>> {
        let r = self.room.clone();
        RUNTIME
            .spawn(async move {
                Ok(r.active_members_no_sync()
                    .await
                    .expect("No members")
                    .into_iter()
                    .map(|member| RoomMember { member })
                    .collect())
            })
            .await?
    }
}

impl std::ops::Deref for Room {
    type Target = MatrixRoom;
    fn deref(&self) -> &MatrixRoom {
        &self.room
    }
}

impl std::ops::Deref for Client {
    type Target = MatrixClient;
    fn deref(&self) -> &MatrixClient {
        &self.client
    }
}

impl Client {
    fn new(client: MatrixClient, state: ClientState) -> Self {
        Client {
            client,
            state: Arc::new(RwLock::new(state)),
        }
    }

    fn start_sync(&self) {
        let client = self.client.clone();
        let state = self.state.clone();
        RUNTIME.spawn(async move {
            client
                .sync_with_callback(matrix_sdk::config::SyncSettings::new(), |_response| async {
                    if !state.read().has_first_synced {
                        state.write().has_first_synced = true
                    }

                    if state.read().should_stop_syncing {
                        state.write().is_syncing = false;
                        return LoopCtrl::Break;
                    } else if !state.read().is_syncing {
                        state.write().is_syncing = true;
                    }
                    LoopCtrl::Continue
                })
                .await;
        });
    }

    /// Indication whether we've received a first sync response since
    /// establishing the client (in memory)
    pub fn has_first_synced(&self) -> bool {
        self.state.read().has_first_synced
    }

    /// Indication whether we are currently syncing
    pub fn is_syncing(&self) -> bool {
        self.state.read().has_first_synced
    }

    /// Is this a guest account?
    pub fn is_guest(&self) -> bool {
        self.state.read().is_guest
    }

    pub async fn restore_token(&self) -> Result<String> {
        let session = self.client.session().await.expect("Missing session");
        let homeurl = self.client.homeserver().await.into();
        Ok(serde_json::to_string(&RestoreToken {
            session,
            homeurl,
            is_guest: self.state.read().is_guest,
        })?)
    }

    pub fn conversations(&self) -> Vec<Room> {
        let r: Vec<_> = self.rooms().into_iter().map(|room| Room { room }).collect();
        r
    }

    // pub async fn get_mxcuri_media(&self, uri: String) -> Result<Vec<u8>> {
    //     let l = self.client.clone();
    //     RUNTIME.spawn(async move {
    //         let user_id = l.user_id().await.expect("No User ID found");
    //         Ok(user_id.as_str().to_string())
    //     }).await?
    // }

    pub async fn user_id(&self) -> Result<String> {
        let l = self.client.clone();
        RUNTIME
            .spawn(async move {
                let user_id = l.user_id().await.expect("No User ID found");
                Ok(user_id.as_str().to_string())
            })
            .await?
    }

    pub async fn room(&self, room_name: String) -> Result<Room> {
        let room_id = RoomId::parse(room_name)?;
        let l = self.client.clone();
        RUNTIME
            .spawn(async move {
                if let Some(room) = l.get_room(&room_id) {
                    return Ok(Room { room });
                }
                bail!("Room not found")
            })
            .await?
    }

    pub async fn display_name(&self) -> Result<String> {
        let l = self.client.clone();
        RUNTIME
            .spawn(async move {
                let display_name = l
                    .account()
                    .get_display_name()
                    .await?
                    .expect("No User ID found");
                Ok(display_name.as_str().to_string())
            })
            .await?
    }

    pub async fn device_id(&self) -> Result<String> {
        let l = self.client.clone();
        RUNTIME
            .spawn(async move {
                let device_id = l.device_id().await.expect("No Device ID found");
                Ok(device_id.as_str().to_string())
            })
            .await?
    }

    pub async fn avatar(&self) -> Result<api::FfiBuffer<u8>> {
        let l = self.client.clone();
        RUNTIME
            .spawn(async move {
                let uri = l
                    .account()
                    .get_avatar_url()
                    .await?
                    .expect("No avatar Url given");
                Ok(api::FfiBuffer::new(
                    l.get_media_content(
                        &MediaRequest {
                            media_type: MediaType::Uri(uri),
                            format: MediaFormat::File,
                        },
                        true,
                    )
                    .await?,
                ))
            })
            .await?
    }
}

pub async fn guest_client(base_path: String, homeurl: String) -> Result<Client> {
    let homeserver = Url::parse(&homeurl)?;
    let config = platform::new_client_config(base_path, homeurl)?;
    let mut guest_registration = register::v3::Request::new();
    guest_registration.kind = register::RegistrationKind::Guest;
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            let register = client.register(guest_registration).await?;
            let session = Session {
                access_token: register.access_token.expect("no access token given"),
                user_id: register.user_id,
                device_id: register
                    .device_id
                    .clone()
                    .expect("device id is given by server"),
            };
            client.restore_login(session).await?;
            let c = Client::new(
                client,
                ClientStateBuilder::default().is_guest(true).build()?,
            );
            c.start_sync();
            Ok(c)
        })
        .await?
}

pub async fn login_with_token(base_path: String, restore_token: String) -> Result<Client> {
    let RestoreToken {
        session,
        homeurl,
        is_guest,
    } = serde_json::from_str(&restore_token)?;
    let homeserver = Url::parse(&homeurl)?;
    let config = platform::new_client_config(base_path, session.user_id.to_string())?;
    // First we need to log in.
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            client.restore_login(session).await?;
            let c = Client::new(
                client,
                ClientStateBuilder::default().is_guest(is_guest).build()?,
            );
            c.start_sync();
            Ok(c)
        })
        .await?
}

pub async fn login_new_client(
    base_path: String,
    username: String,
    password: String,
) -> Result<Client> {
    let user = Box::<UserId>::try_from(username.clone())?;
    let config = platform::new_client_config(base_path, username)?.user_id(&user);
    // First we need to log in.
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            client.login(user, &password, None, None).await?;
            let c = Client::new(
                client,
                ClientStateBuilder::default().is_guest(false).build()?,
            );
            c.start_sync();
            Ok(c)
        })
        .await?
}

fn init_logging(filter: Option<String>) -> Result<()> {
    platform::init_logging(filter)?;
    Ok(())
}
