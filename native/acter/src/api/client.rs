use acter_core::{
    client::CoreClient, executor::Executor, models::AnyActerModel, store::Store, templates::Engine,
    CustomAuthSession, RestoreToken,
};
use anyhow::{Context, Result};
use base64ct::{Base64UrlUnpadded, Encoding};
use core::time::Duration;
use derive_builder::Builder;
use eyeball_im::{ObservableVector, Vector};
use futures::{
    future::join_all,
    stream::{Stream, StreamExt},
};
use matrix_sdk::{
    media::{MediaRequestParameters, UniqueKey},
    room::Room as SdkRoom,
    Client as SdkClient,
};
use matrix_sdk_base::{
    ruma::{
        device_id, events::room::MediaSource, IdParseError, OwnedDeviceId, OwnedMxcUri,
        OwnedRoomAliasId, OwnedRoomId, OwnedRoomOrAliasId, OwnedServerName, OwnedUserId,
        RoomAliasId, RoomId, RoomOrAliasId, UserId,
    },
    RoomStateFilter,
};
use std::{io::Write, ops::Deref, path::PathBuf, sync::Arc};
use tokio::{
    sync::{broadcast::Receiver, RwLock},
    time,
};
use tokio_stream::wrappers::BroadcastStream;
use tracing::{error, trace};

use crate::{Account, Convo, OptionString, Room, Space, ThumbnailSize, RUNTIME};

use super::{
    api::FfiBuffer, device::DeviceController, invitation::InvitationController,
    typing::TypingController, verification::VerificationController,
};

mod sync;

pub use sync::{HistoryLoadState, SyncState};

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

    #[builder(default)]
    pub db_passphrase: Option<String>,
}

#[derive(Clone, Debug)]
pub struct Client {
    pub(crate) core: CoreClient,
    pub(crate) state: Arc<RwLock<ClientState>>,
    pub(crate) invitation_controller: InvitationController,
    pub(crate) verification_controller: VerificationController,
    pub(crate) device_controller: DeviceController,
    pub(crate) typing_controller: TypingController,
    pub spaces: Arc<RwLock<ObservableVector<Space>>>,
    pub convos: Arc<RwLock<ObservableVector<Convo>>>,
}

impl Deref for Client {
    type Target = SdkClient;
    fn deref(&self) -> &SdkClient {
        self.core.client()
    }
}

// internal API
impl Client {
    pub(crate) async fn source_binary(
        &self,
        source: MediaSource,
        thumb_size: Option<Box<ThumbnailSize>>,
    ) -> Result<FfiBuffer<u8>> {
        // any variable in self can’t be called directly in spawn
        let client = self.core.client().clone();
        let format = ThumbnailSize::parse_into_media_format(thumb_size);
        let request = MediaRequestParameters { source, format };
        trace!(?request, "tasked to get source binary");
        RUNTIME
            .spawn(async move {
                let buf = client.media().get_media_content(&request, true).await?;
                Ok(FfiBuffer::new(buf))
            })
            .await?
    }

    pub(crate) async fn source_binary_tmp_path(
        &self,
        source: MediaSource,
        thumb_size: Option<Box<ThumbnailSize>>,
        tmp_path: String,
        file_suffix: &str,
    ) -> Result<String> {
        // any variable in self can’t be called directly in spawn
        let client = self.core.client().clone();
        let format = ThumbnailSize::parse_into_media_format(thumb_size);
        let request = MediaRequestParameters { source, format };
        let path = PathBuf::from(tmp_path).join(format!(
            "{}.{file_suffix}",
            Base64UrlUnpadded::encode_string(request.unique_key().as_bytes())
        ));
        trace!(
            ?request,
            ?path,
            "tasked to get source binary and store to file"
        );
        if !path.exists() {
            // only download if the temp isn’t already there.
            let target_path = path.clone();
            RUNTIME
                .spawn(async move {
                    let data = client.media().get_media_content(&request, true).await?;
                    let mut file = std::fs::File::create(target_path)?;
                    file.write_all(&data)?;
                    anyhow::Ok(())
                })
                .await?;
        }

        return path
            .to_str()
            .map(|s| s.to_string())
            .context("Path was generated from strings. Must be string");
    }

    pub async fn join_room(
        &self,
        room_id_or_alias: String,
        server_name: Option<String>,
    ) -> Result<Room> {
        let parsed = RoomOrAliasId::parse(room_id_or_alias)?;
        let server_names = match server_name {
            Some(inner) => vec![OwnedServerName::try_from(inner)?],
            None => parsed
                .server_name()
                .map(|i| vec![i.to_owned()])
                .unwrap_or_default(),
        };

        self.join_room_typed(parsed, server_names).await
    }
    pub async fn join_room_typed(
        &self,
        room_id_or_alias: OwnedRoomOrAliasId,
        server_names: Vec<OwnedServerName>,
    ) -> Result<Room> {
        let core = self.core.clone();
        RUNTIME
            .spawn(async move {
                let joined = core
                    .client()
                    .join_room_by_id_or_alias(&room_id_or_alias, server_names.as_slice())
                    .await?;
                Ok(Room::new(core.clone(), joined))
            })
            .await?
    }
}

// external API
impl Client {
    pub async fn new(client: SdkClient, state: ClientState) -> Result<Self> {
        let core = CoreClient::new(client.clone()).await?;
        let mut cl = Client {
            core: core.clone(),
            state: Arc::new(RwLock::new(state)),
            spaces: Default::default(),
            convos: Default::default(),
            invitation_controller: InvitationController::new(core.clone()),
            verification_controller: VerificationController::new(),
            device_controller: DeviceController::new(client),
            typing_controller: TypingController::new(),
        };
        cl.load_from_cache().await;
        cl.setup_handlers();
        Ok(cl)
    }

    async fn load_from_cache(&self) {
        let (spaces, chats) = self.get_spaces_and_chats().await;
        // FIXME for a lack of a better system, we just sort by room-id
        let mut space_types: Vector<Space> = spaces
            .into_iter()
            .map(|r| Space::new(self.clone(), r))
            .collect();
        space_types.sort();

        self.spaces.write().await.append(space_types);
        let mut values = join_all(chats.into_iter().map(|r| Convo::new(self.clone(), r))).await;
        values.sort();
        self.convos.write().await.append(values.into());
    }

    async fn get_spaces_and_chats(&self) -> (Vec<Room>, Vec<Room>) {
        let client = self.core.clone();
        // only include items we are ourselves are currently joined in
        self.rooms_filtered(RoomStateFilter::JOINED)
            .into_iter()
            .fold(
                (Vec::new(), Vec::new()),
                move |(mut spaces, mut convos), room| {
                    let inner = Room::new(client.clone(), room);

                    if inner.is_space() {
                        spaces.push(inner);
                    } else {
                        convos.push(inner);
                    }
                    (spaces, convos)
                },
            )
    }

    pub async fn resolve_room_alias(&self, alias_id: OwnedRoomAliasId) -> Result<OwnedRoomId> {
        let client = self.core.client().clone();
        RUNTIME
            .spawn(async move {
                let response = client.resolve_room_alias(&alias_id).await?;
                anyhow::Ok(response.room_id)
            })
            .await?
    }

    pub fn store(&self) -> &Store {
        self.core.store()
    }

    pub fn executor(&self) -> &Executor {
        self.core.executor()
    }

    pub async fn template_engine(&self, template: &str) -> Result<Engine> {
        let engine = self.core.template_engine(template).await?;
        Ok(engine)
    }

    /// Is this a guest account?
    pub fn is_guest(&self) -> bool {
        match self.state.try_read() {
            Ok(r) => r.is_guest,
            Err(e) => false,
        }
    }

    pub async fn restore_token(&self) -> Result<String> {
        let session = self.session().context("Missing session")?;
        let homeurl = self.homeserver();
        let (is_guest, db_passphrase) = {
            let state = self.state.try_read()?;
            (state.is_guest, state.db_passphrase.clone())
        };
        let result = RestoreToken::serialized(
            CustomAuthSession {
                user_id: session.meta().user_id.clone(),
                device_id: session.meta().device_id.clone(),
                access_token: session.access_token().to_string(),
            },
            homeurl,
            is_guest,
            db_passphrase,
        )?;
        Ok(result)
    }

    // pub async fn get_mxcuri_media(&self, uri: String) -> Result<Vec<u8>> {
    //     let client = self.core.clone();
    //     RUNTIME.spawn(async move {
    //         let user_id = client.user_id().await.context("You must be logged in to do that")?;
    //         Ok(user_id.to_string())
    //     }).await?
    // }

    pub async fn upload_media(&self, uri: String) -> Result<OwnedMxcUri> {
        let client = self.core.client().clone();
        let path = PathBuf::from(uri);

        RUNTIME
            .spawn(async move {
                let guess = mime_guess::from_path(path.clone());
                let content_type = guess.first().context("don’t know mime type")?;
                let buf = std::fs::read(path)?;
                let response = client.media().upload(&content_type, buf, None).await?;
                Ok(response.content_uri)
            })
            .await?
    }

    pub fn user_id(&self) -> Result<OwnedUserId> {
        self.core
            .client()
            .user_id()
            .context("You must be logged in to do that")
            .map(|x| x.to_owned())
    }

    fn user_id_ref(&self) -> Option<&UserId> {
        self.core.client().user_id()
    }

    pub async fn room(&self, room_id_or_alias: String) -> Result<Room> {
        let id_or_alias = RoomOrAliasId::parse(room_id_or_alias)?;
        self.room_typed(&id_or_alias).await
    }

    // ***_typed fn accepts rust-typed input, not string-based one
    async fn room_typed(&self, room_id_or_alias: &RoomOrAliasId) -> Result<Room> {
        if room_id_or_alias.is_room_id() {
            let room_id = RoomId::parse(room_id_or_alias.as_str())?;
            let room = self.room_by_id_typed(&room_id)?;
            return Ok(Room::new(self.core.clone(), room));
        }

        let room_alias = RoomAliasId::parse(room_id_or_alias.as_str())?;
        self.room_by_alias_typed(&room_alias).await
    }

    // ***_typed fn accepts rust-typed input, not string-based one
    pub fn room_by_id_typed(&self, room_id: &RoomId) -> Result<SdkRoom> {
        self.core
            .client()
            .get_room(room_id)
            .context("Room not found")
    }

    pub async fn wait_for_room(&self, room_id: String, timeout: Option<u8>) -> Result<bool> {
        let executor = self.core.executor().clone();
        let mut subscription = executor.subscribe(room_id.clone());
        if self.room_by_id_typed(&RoomId::parse(room_id)?).is_ok() {
            return Ok(true);
        }

        RUNTIME
            .spawn(async move {
                let waiter = subscription.recv();
                if let Some(tm) = timeout {
                    time::timeout(Duration::from_secs(tm as u64), waiter).await??;
                } else {
                    waiter.await?;
                }
                Ok(true)
            })
            .await?
    }

    // ***_typed fn accepts rust-typed input, not string-based one
    async fn room_by_alias_typed(&self, room_alias: &RoomAliasId) -> Result<Room> {
        let client = self.core.client();
        for r in client.rooms() {
            // looping locally first
            if let Some(con_alias) = r.canonical_alias() {
                if con_alias == room_alias {
                    return Ok(Room::new(self.core.clone(), r));
                }
            }
            for alt_alias in r.alt_aliases() {
                if alt_alias == room_alias {
                    return Ok(Room::new(self.core.clone(), r));
                }
            }
        }
        // nothing found, try remote:
        let response = client.resolve_room_alias(room_alias).await?;
        let room = self.room_by_id_typed(&response.room_id)?;
        Ok(Room::new(self.core.clone(), room))
    }

    pub fn dm_with_user(&self, user_id: String) -> Result<OptionString> {
        let user_id = UserId::parse(user_id)?;
        let room_id = self
            .core
            .client()
            .get_dm_room(&user_id)
            .map(|x| x.room_id().to_string());
        Ok(OptionString::new(room_id))
    }

    pub fn subscribe_stream(&self, key: String) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe(key)).map(|_| true)
    }

    pub fn subscribe(&self, key: String) -> Receiver<()> {
        self.executor().subscribe(key)
    }

    pub async fn wait_for(&self, key: String, timeout: Option<u8>) -> Result<AnyActerModel> {
        let executor = self.core.executor().clone();

        RUNTIME
            .spawn(async move {
                let waiter = executor.wait_for(key);
                let Some(tm) = timeout else {
                    return Ok(waiter.await?);
                };
                Ok(time::timeout(Duration::from_secs(tm as u64), waiter).await??)
            })
            .await?
    }

    pub fn account(&self) -> Result<Account> {
        let account = self.core.client().account();
        let user_id = self.user_id()?;
        Ok(Account::new(account, user_id, self.clone()))
    }

    pub fn device_id(&self) -> Result<OwnedDeviceId> {
        self.core
            .client()
            .device_id()
            .context("DeviceId not found")
            .map(|x| x.to_owned())
    }

    pub async fn verified_device(&self, dev_id: String) -> Result<bool> {
        let client = self.core.client().clone();
        let user_id = self.user_id()?;
        RUNTIME
            .spawn(async move {
                client
                    .encryption()
                    .get_device(&user_id, device_id!(dev_id.as_str()))
                    .await?
                    .context("Unable to find device")
                    .map(|x| x.is_verified())
            })
            .await?
    }

    pub async fn logout(&mut self) -> Result<bool> {
        if let Ok(mut w) = self.state.try_write() {
            w.should_stop_syncing = true;
        }
        let client = self.core.client().clone();

        self.invitation_controller.remove_event_handler();
        self.verification_controller
            .remove_to_device_event_handler(&client);
        self.verification_controller
            .remove_sync_event_handler(&client);
        self.typing_controller.remove_event_handler(&client);

        RUNTIME
            .spawn(async move {
                match client.matrix_auth().logout().await {
                    Ok(resp) => Ok(true),
                    Err(e) => {
                        error!("logout error: {:?}", e);
                        Ok(false)
                    }
                }
            })
            .await?
    }
}
