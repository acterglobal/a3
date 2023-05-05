use anyhow::{Context, Result};
use futures::{
    channel::mpsc::{channel, Receiver, Sender},
    StreamExt,
};
use log::{info, warn};
use matrix_sdk::{
    encryption::identities::Device,
    locks::Mutex,
    ruma::{
        device_id, events::key::verification::VerificationMethod, MilliSecondsSinceUnixEpoch,
        OwnedDeviceId, OwnedUserId,
    },
    sync::SyncResponse,
    Client as MatrixClient,
};
use std::sync::Arc;

use super::{client::Client, RUNTIME};

#[derive(Clone, Debug)]
pub struct DeviceChangedEvent {
    client: MatrixClient,
}

impl DeviceChangedEvent {
    pub(crate) fn new(client: &MatrixClient) -> Self {
        DeviceChangedEvent {
            client: client.clone(),
        }
    }

    pub async fn device_records(&self, verified: bool) -> Result<Vec<DeviceRecord>> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let user_id = client
                    .user_id()
                    .expect("guest user cannot get the verified devices");
                let mut records: Vec<DeviceRecord> = vec![];
                let response = client.devices().await?;
                for device in client
                    .encryption()
                    .get_user_devices(user_id)
                    .await?
                    .devices()
                {
                    if device.is_verified() == verified {
                        if let Some(dev) = response
                            .devices
                            .iter()
                            .find(|e| e.device_id == device.device_id())
                        {
                            records.push(DeviceRecord::new(
                                &device,
                                dev.last_seen_ip.clone(),
                                dev.last_seen_ts,
                            ));
                        } else {
                            records.push(DeviceRecord::new(&device, None, None));
                        }
                    }
                }
                Ok(records)
            })
            .await?
    }

    pub async fn request_verification_to_user(&self) -> Result<bool> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let user_id = client
                    .user_id()
                    .expect("guest user cannot request verification");
                let user = client
                    .encryption()
                    .get_user_identity(user_id)
                    .await?
                    .context("alice should get user identity")?;
                user.request_verification().await?;
                Ok(true)
            })
            .await?
    }

    pub async fn request_verification_to_device(&self, dev_id: String) -> Result<bool> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let user_id = client
                    .user_id()
                    .expect("guest user cannot request verification");
                let dev = client
                    .encryption()
                    .get_device(user_id, device_id!(dev_id.as_str()))
                    .await
                    .context("alice should get device")?
                    .unwrap();
                dev.request_verification_with_methods(vec![VerificationMethod::SasV1])
                    .await?;
                Ok(true)
            })
            .await?
    }

    pub async fn request_verification_to_user_with_methods(
        &self,
        methods: &mut Vec<String>,
    ) -> Result<bool> {
        let client = self.client.clone();
        let values = (*methods).iter().map(|e| e.as_str().into()).collect();
        RUNTIME
            .spawn(async move {
                let user_id = client
                    .user_id()
                    .expect("guest user cannot request verification");
                let user = client
                    .encryption()
                    .get_user_identity(user_id)
                    .await?
                    .context("alice should get user identity")?;
                user.request_verification_with_methods(values).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn request_verification_to_device_with_methods(
        &self,
        dev_id: String,
        methods: &mut Vec<String>,
    ) -> Result<bool> {
        let client = self.client.clone();
        let values = (*methods).iter().map(|e| e.as_str().into()).collect();
        RUNTIME
            .spawn(async move {
                let user_id = client
                    .user_id()
                    .expect("guest user cannot request verification");
                let dev = client
                    .encryption()
                    .get_device(user_id, device_id!(dev_id.as_str()))
                    .await
                    .context("alice should get device")?
                    .unwrap();
                dev.request_verification_with_methods(values).await?;
                Ok(true)
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct DeviceLeftEvent {
    client: MatrixClient,
}

impl DeviceLeftEvent {
    pub(crate) fn new(client: &MatrixClient) -> Self {
        DeviceLeftEvent {
            client: client.clone(),
        }
    }

    pub async fn device_records(&self, deleted: bool) -> Result<Vec<DeviceRecord>> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let user_id = client
                    .user_id()
                    .expect("guest user cannot get the deleted devices");
                let mut records: Vec<DeviceRecord> = vec![];
                let response = client.devices().await?;
                for device in client
                    .encryption()
                    .get_user_devices(user_id)
                    .await?
                    .devices()
                {
                    if device.is_deleted() == deleted {
                        if let Some(dev) = response
                            .devices
                            .iter()
                            .find(|e| e.device_id == device.device_id())
                        {
                            records.push(DeviceRecord::new(
                                &device,
                                dev.last_seen_ip.clone(),
                                dev.last_seen_ts,
                            ));
                        } else {
                            records.push(DeviceRecord::new(&device, None, None));
                        }
                    }
                }
                Ok(records)
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct DeviceRecord {
    device: Device,
    last_seen_ip: Option<String>,
    last_seen_ts: Option<MilliSecondsSinceUnixEpoch>,
}

impl DeviceRecord {
    pub(crate) fn new(
        device: &Device,
        last_seen_ip: Option<String>,
        last_seen_ts: Option<MilliSecondsSinceUnixEpoch>,
    ) -> Self {
        DeviceRecord {
            device: device.clone(),
            last_seen_ip,
            last_seen_ts,
        }
    }

    pub fn verified(&self) -> bool {
        self.device.is_verified()
    }

    pub fn deleted(&self) -> bool {
        self.device.is_deleted()
    }

    pub fn user_id(&self) -> OwnedUserId {
        self.device.user_id().to_owned()
    }

    pub fn device_id(&self) -> OwnedDeviceId {
        self.device.device_id().to_owned()
    }

    pub fn display_name(&self) -> Option<String> {
        self.device.display_name().map(|s| s.to_string())
    }

    pub fn last_seen_ip(&self) -> Option<String> {
        self.last_seen_ip.clone()
    }

    pub fn last_seen_ts(&self) -> Option<u64> {
        self.last_seen_ts.map(|x| x.get().into())
    }
}

#[derive(Clone, Debug)]
pub(crate) struct DeviceController {
    changed_event_tx: Sender<DeviceChangedEvent>,
    changed_event_rx: Arc<Mutex<Option<Receiver<DeviceChangedEvent>>>>,
    left_event_tx: Sender<DeviceLeftEvent>,
    left_event_rx: Arc<Mutex<Option<Receiver<DeviceLeftEvent>>>>,
}

impl DeviceController {
    pub fn new() -> Self {
        let (changed_event_tx, changed_event_rx) = channel::<DeviceChangedEvent>(10); // dropping after more than 10 items queued
        let (left_event_tx, left_event_rx) = channel::<DeviceLeftEvent>(10); // dropping after more than 10 items queued
        DeviceController {
            changed_event_tx,
            changed_event_rx: Arc::new(Mutex::new(Some(changed_event_rx))),
            left_event_tx,
            left_event_rx: Arc::new(Mutex::new(Some(left_event_rx))),
        }
    }

    pub fn process_device_lists(&mut self, client: &MatrixClient, response: &SyncResponse) {
        info!("process device lists: {:?}", response);

        // avoid device changed event in case that user joined room
        if response.rooms.join.is_empty() {
            let current_user_id = client
                .user_id()
                .expect("guest user cannot handle the device changed event");
            for user_id in response.device_lists.changed.clone().into_iter() {
                info!("device-changed user_id: {}", user_id);
                if *user_id == *current_user_id {
                    let evt = DeviceChangedEvent::new(client);
                    if let Err(e) = self.changed_event_tx.try_send(evt) {
                        warn!("Dropping devices changed event: {}", e);
                    }
                }
            }
        }

        // avoid device left event in case that user left room
        if response.rooms.leave.is_empty() {
            let current_user_id = client
                .user_id()
                .expect("guest user cannot handle the device left event");
            for user_id in response.device_lists.left.clone().into_iter() {
                info!("device-left user_id: {}", user_id);
                if *user_id == *current_user_id {
                    let evt = DeviceLeftEvent::new(client);
                    if let Err(e) = self.left_event_tx.try_send(evt) {
                        warn!("Dropping devices left event: {}", e);
                    }
                }
            }
        }
    }
}

impl Client {
    pub fn device_changed_event_rx(&self) -> Option<Receiver<DeviceChangedEvent>> {
        match self.device_controller.changed_event_rx.try_lock() {
            Ok(mut r) => r.take(),
            Err(e) => None,
        }
    }

    pub fn device_left_event_rx(&self) -> Option<Receiver<DeviceLeftEvent>> {
        match self.device_controller.left_event_rx.try_lock() {
            Ok(mut r) => r.take(),
            Err(e) => None,
        }
    }
}
