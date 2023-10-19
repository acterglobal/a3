use anyhow::{Context, Result};
use futures::{
    channel::mpsc::{channel, Receiver, Sender},
    pin_mut,
    stream::StreamExt,
};
use matrix_sdk::{executor::JoinHandle, Client as SdkClient};
use ruma_common::{device_id, OwnedDeviceId};
use std::{
    sync::Arc,
    time::{Duration, SystemTime, UNIX_EPOCH},
};
use tokio::sync::Mutex;
use tracing::{error, info};

use super::{client::Client, common::DeviceRecord, RUNTIME};

#[derive(Clone, Debug)]
pub struct DeviceNewEvent {
    client: SdkClient,
    device_id: OwnedDeviceId,
}

impl DeviceNewEvent {
    pub(crate) fn new(client: &SdkClient, device_id: OwnedDeviceId) -> Self {
        DeviceNewEvent {
            client: client.clone(),
            device_id,
        }
    }

    pub(crate) fn client(&self) -> SdkClient {
        self.client.clone()
    }

    pub fn device_id(&self) -> OwnedDeviceId {
        self.device_id.clone()
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
pub struct DeviceChangedEvent {
    client: SdkClient,
    device_id: OwnedDeviceId,
}

impl DeviceChangedEvent {
    pub(crate) fn new(client: &SdkClient, device_id: OwnedDeviceId) -> Self {
        DeviceChangedEvent {
            client: client.clone(),
            device_id,
        }
    }

    pub fn device_id(&self) -> OwnedDeviceId {
        self.device_id.clone()
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
    new_event_rx: Arc<Mutex<Option<Receiver<DeviceNewEvent>>>>,
    changed_event_rx: Arc<Mutex<Option<Receiver<DeviceChangedEvent>>>>,
    listener: Arc<JoinHandle<()>>,
}

impl DeviceController {
    pub fn new(client: SdkClient) -> Self {
        let (mut new_event_tx, new_event_rx) = channel::<DeviceNewEvent>(10); // dropping after more than 10 items queued
        let (mut changed_event_tx, changed_event_rx) = channel::<DeviceChangedEvent>(10); // dropping after more than 10 items queued

        let listener = RUNTIME.spawn(async move {
            let devices_stream = client
                .encryption()
                .devices_stream()
                .await
                .expect("We have to get devices stream");
            let my_user_id = client
                .user_id()
                .expect("We should know our user id afte we have logged in");
            pin_mut!(devices_stream);

            while let Some(device_updates) = devices_stream.next().await {
                if !client.logged_in() {
                    break;
                }
                if let Some(user_devices) = device_updates.new.get(my_user_id) {
                    for device in user_devices.values() {
                        let dev_id = device.device_id().to_owned();
                        info!("device-new device id: {}", dev_id);
                        let evt = DeviceNewEvent::new(&client, dev_id);
                        if let Err(e) = new_event_tx.try_send(evt) {
                            error!("Dropping devices new event: {}", e);
                        }
                    }
                }
                if let Some(user_devices) = device_updates.changed.get(my_user_id) {
                    for device in user_devices.values() {
                        let dev_id = device.device_id().to_owned();
                        info!("device-changed device id: {}", dev_id);
                        let evt = DeviceChangedEvent::new(&client, dev_id);
                        if let Err(e) = changed_event_tx.try_send(evt) {
                            error!("Dropping devices changed event: {}", e);
                        }
                    }
                }
            }
        });

        DeviceController {
            new_event_rx: Arc::new(Mutex::new(Some(new_event_rx))),
            changed_event_rx: Arc::new(Mutex::new(Some(changed_event_rx))),
            listener: Arc::new(listener),
        }
    }
}

impl Client {
    pub fn device_new_event_rx(&self) -> Option<Receiver<DeviceNewEvent>> {
        match self.device_controller.new_event_rx.try_lock() {
            Ok(mut r) => r.take(),
            Err(e) => None,
        }
    }

    pub fn device_changed_event_rx(&self) -> Option<Receiver<DeviceChangedEvent>> {
        match self.device_controller.changed_event_rx.try_lock() {
            Ok(mut r) => r.take(),
            Err(e) => None,
        }
    }
}
