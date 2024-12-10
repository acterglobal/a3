use anyhow::{Context, Result};
use futures::{
    pin_mut,
    stream::{Stream, StreamExt},
};
use matrix_sdk::{executor::JoinHandle, Client as SdkClient};
use matrix_sdk_base::ruma::{OwnedDeviceId, OwnedUserId};
use std::{
    sync::Arc,
    time::{Duration, SystemTime, UNIX_EPOCH},
};
use tokio::sync::broadcast::{channel, Receiver, Sender};
use tokio_stream::wrappers::BroadcastStream;
use tracing::{error, info};

use super::{client::Client, common::DeviceRecord, RUNTIME};

#[derive(Clone, Debug, Default)]
pub struct DeviceEvent {
    new_devices: Vec<OwnedDeviceId>,
    changed_devices: Vec<OwnedDeviceId>,
}

impl DeviceEvent {
    pub(crate) fn new(
        new_devices: Vec<OwnedDeviceId>,
        changed_devices: Vec<OwnedDeviceId>,
    ) -> Self {
        DeviceEvent {
            new_devices,
            changed_devices,
        }
    }

    pub fn new_devices(&self) -> Vec<String> {
        self.new_devices
            .iter()
            .map(OwnedDeviceId::to_string)
            .collect()
    }

    pub fn changed_devices(&self) -> Vec<String> {
        self.changed_devices
            .iter()
            .map(OwnedDeviceId::to_string)
            .collect()
    }
}

#[derive(Clone, Debug)]
pub(crate) struct DeviceController {
    event_tx: Sender<DeviceEvent>, // keep it resident in memory
    event_rx: Arc<Receiver<DeviceEvent>>,
    listener: Arc<JoinHandle<()>>, // keep it resident in memory
}

impl DeviceController {
    pub fn new(client: SdkClient) -> Self {
        let (event_tx, event_rx) = channel::<DeviceEvent>(10); // dropping after more than 10 items queued

        let mut tx = event_tx.clone();

        let listener = RUNTIME.spawn(async move {
            let devices_stream = client
                .encryption()
                .devices_stream()
                .await
                .expect("Stream of devices needed");
            let my_id = client.user_id().expect("UserId needed");
            pin_mut!(devices_stream);

            while let Some(device_updates) = devices_stream.next().await {
                if !client.logged_in() {
                    break;
                }
                let mut new_devices = vec![];
                let mut changed_devices = vec![];
                if let Some(user_devices) = device_updates.new.get(my_id) {
                    for (dev_id, dev) in user_devices {
                        info!("device-new device id: {}", dev_id);
                        new_devices.push(dev_id.to_owned());
                    }
                }
                if let Some(user_devices) = device_updates.changed.get(my_id) {
                    for (dev_id, dev) in user_devices {
                        info!("device-changed device id: {}", dev_id);
                        changed_devices.push(dev_id.to_owned());
                    }
                }
                if !new_devices.is_empty() || !changed_devices.is_empty() {
                    let evt = DeviceEvent::new(new_devices, changed_devices);
                    if let Err(e) = tx.send(evt) {
                        error!("Dropping device event: {}", e);
                    }
                }
            }
        });

        DeviceController {
            event_tx,
            event_rx: Arc::new(event_rx),
            listener: Arc::new(listener),
        }
    }
}

impl Client {
    pub fn device_event_rx(&self) -> impl Stream<Item = DeviceEvent> {
        BroadcastStream::new(self.device_controller.event_rx.resubscribe())
            .map(|o| o.unwrap_or_default())
    }

    pub async fn device_records(&self, verified: bool) -> Result<Vec<DeviceRecord>> {
        let user_id = self.user_id()?;
        let this_device_id = self.device_id()?;
        let client = self.core.client().clone();

        RUNTIME
            .spawn(async move {
                let response = client.devices().await?;
                let crypto_devices = client.encryption().get_user_devices(&user_id).await?;
                let mut sessions = vec![];
                for device in response.devices {
                    let is_verified = crypto_devices.get(&device.device_id).is_some_and(|d| {
                        d.is_cross_signed_by_owner() || d.is_verified_with_cross_signing()
                    });
                    let mut is_active = false;
                    if let Some(last_seen_ts) = device.last_seen_ts {
                        let limit = SystemTime::now()
                            .checked_sub(Duration::from_secs(90 * 24 * 60 * 60))
                            .context("Unable to get time of 90 days ago")?
                            .duration_since(UNIX_EPOCH)?;
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
                                device.device_id == this_device_id,
                            ));
                        } else {
                            sessions.push(DeviceRecord::new(
                                device.device_id.clone(),
                                device.display_name.clone(),
                                None,
                                None,
                                is_verified,
                                is_active,
                                device.device_id == this_device_id,
                            ));
                        }
                    }
                }
                Ok(sessions)
            })
            .await?
    }
}
