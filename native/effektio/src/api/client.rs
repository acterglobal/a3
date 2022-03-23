use super::{api, Room, UserId, RUNTIME};
use anyhow::{bail, Context, Result};
use derive_builder::Builder;
use effektio_core::ruma::api::client::account::register;
use effektio_core::RestoreToken;
use futures::{stream, Stream};
use lazy_static::lazy_static;
pub use matrix_sdk::ruma::{self, DeviceId, MxcUri, RoomId, ServerName};
use matrix_sdk::{
    media::{MediaFormat, MediaRequest, MediaType},
    room::Room as MatrixRoom,
    Client as MatrixClient, LoopCtrl, Session,
};
use parking_lot::RwLock;
use std::sync::Arc;
use url::Url;

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

impl std::ops::Deref for Client {
    type Target = MatrixClient;
    fn deref(&self) -> &MatrixClient {
        &self.client
    }
}

impl Client {
    pub(crate) fn new(client: MatrixClient, state: ClientState) -> Self {
        Client {
            client,
            state: Arc::new(RwLock::new(state)),
        }
    }

    pub(crate) fn start_sync(&self) {
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
        let session = self.client.session().await.context("Missing session")?;
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
                let user_id = l.user_id().await.context("No User ID found")?;
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
                    .context("No User ID found")?;
                Ok(display_name.as_str().to_string())
            })
            .await?
    }

    pub async fn device_id(&self) -> Result<String> {
        let l = self.client.clone();
        RUNTIME
            .spawn(async move {
                let device_id = l.device_id().await.context("No Device ID found")?;
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
                    .context("No avatar Url given")?;
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
