use anyhow::{Context, Result};
use futures::{
    channel::mpsc::{channel, Receiver, Sender},
    stream::StreamExt,
};
use matrix_sdk::{
    ruma::device_id,
    sync::SyncResponse,
    Client as SdkClient,
};
use std::{
    sync::Arc,
    time::{Duration, SystemTime, UNIX_EPOCH},
};
use tokio::sync::Mutex;
use tracing::{error, info};

use super::{client::Client, common::DeviceRecord, RUNTIME};

#[derive(Clone, Debug)]
pub struct DeviceChangedEvent {
    client: SdkClient,
}

impl DeviceChangedEvent {
    pub(crate) fn new(client: &SdkClient) -> Self {
        DeviceChangedEvent {
            client: client.clone(),
        }
    }

    pub(crate) fn client(&self) -> SdkClient {
        self.client.clone()
    }

    pub async fn device_records(&self, verified: bool) -> Result<Vec<DeviceRecord>> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let user_id = client
                    .user_id()
                    .context("guest user cannot get the verified devices")?;
                let response = client.devices().await?;
                let crypto_devices = client
                    .encryption()
                    .get_user_devices(user_id)
                    .await
                    .context("Couldn't get crypto devices")?;
                let mut sessions = vec![];
                for device in response.devices {
                    let is_verified = crypto_devices.get(&device.device_id).is_some_and(|d| {
                        d.is_cross_signed_by_owner() || d.is_verified_with_cross_signing()
                    });
                    let mut is_active = false;
                    if let Some(last_seen_ts) = device.last_seen_ts {
                        let limit = SystemTime::now()
                            .checked_sub(Duration::from_secs(90 * 24 * 60 * 60))
                            .context("Couldn't get time of 90 days ago")?
                            .duration_since(UNIX_EPOCH)
                            .context("Couldn't calculate duration from Unix epoch")?;
                        let secs: u64 = last_seen_ts.as_secs().into();
                        if secs < limit.as_secs() {
                            is_active = true;
                        }
                    }
                    if is_verified == verified {
                        let found = crypto_devices
                            .get(&device.device_id)
                            .is_some_and(|d| d.device_id() == device.device_id);
                        if found {
                            sessions.push(DeviceRecord::new(
                                device.device_id.clone(),
                                device.display_name.clone(),
                                device.last_seen_ts,
                                device.last_seen_ip.clone(),
                                is_verified,
                                is_active,
                            ));
                        } else {
                            sessions.push(DeviceRecord::new(
                                device.device_id.clone(),
                                device.display_name.clone(),
                                None,
                                None,
                                is_verified,
                                is_active,
                            ));
                        }
                    }
                }
                Ok(sessions)
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct DeviceLeftEvent {
    client: SdkClient,
}

impl DeviceLeftEvent {
    pub(crate) fn new(client: &SdkClient) -> Self {
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
                    .context("guest user cannot get the deleted devices")?;
                let response = client.devices().await?;
                let crypto_devices = client
                    .encryption()
                    .get_user_devices(user_id)
                    .await
                    .context("Couldn't get crypto devices")?;
                let mut sessions = vec![];
                for device in response.devices {
                    let is_verified = crypto_devices.get(&device.device_id).is_some_and(|d| {
                        d.is_cross_signed_by_owner() || d.is_verified_with_cross_signing()
                    });
                    let mut is_active = false;
                    if let Some(last_seen_ts) = device.last_seen_ts {
                        let limit = SystemTime::now()
                            .checked_sub(Duration::from_secs(90 * 24 * 60 * 60))
                            .context("Couldn't get time of 90 days ago")?
                            .duration_since(UNIX_EPOCH)
                            .context("Couldn't calculate duration from Unix epoch")?;
                        let secs: u64 = last_seen_ts.as_secs().into();
                        if secs < limit.as_secs() {
                            is_active = true;
                        }
                    }
                    let is_deleted = crypto_devices
                        .get(&device.device_id)
                        .is_some_and(|d| d.is_deleted());
                    if is_deleted == deleted {
                        let found = crypto_devices
                            .get(&device.device_id)
                            .is_some_and(|d| d.device_id() == device.device_id);
                        if found {
                            sessions.push(DeviceRecord::new(
                                device.device_id.clone(),
                                device.display_name.clone(),
                                device.last_seen_ts,
                                device.last_seen_ip.clone(),
                                is_verified,
                                is_active,
                            ));
                        } else {
                            sessions.push(DeviceRecord::new(
                                device.device_id.clone(),
                                device.display_name.clone(),
                                None,
                                None,
                                is_verified,
                                is_active,
                            ));
                        }
                    }
                }
                Ok(sessions)
            })
            .await?
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

    pub fn process_device_lists(&mut self, client: &SdkClient, response: &SyncResponse) {
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
                        error!("Dropping devices changed event: {}", e);
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
                        error!("Dropping devices left event: {}", e);
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
