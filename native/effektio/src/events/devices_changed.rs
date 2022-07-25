use anyhow::Result;
use futures::channel::mpsc::Sender;
use matrix_sdk::{encryption::identities::Device as MatrixDevice, Client};

use super::RUNTIME;

#[derive(Clone, Debug)]
pub struct DevicesChangedEvent {
    client: Client,
}

impl DevicesChangedEvent {
    pub(crate) fn new(client: &Client) -> Self {
        Self {
            client: client.clone(),
        }
    }

    pub async fn get_unverified_devices(&self) -> Result<Vec<Device>> {
        let c = self.client.clone();
        RUNTIME
            .spawn(async move {
                let user_id = c
                    .user_id()
                    .expect("guest user cannot get unverified devices");
                let mut devices: Vec<Device> = vec![];
                for dev in c.encryption().get_user_devices(user_id).await?.devices() {
                    if !dev.clone().verified() {
                        devices.push(Device::new(dev));
                    }
                }
                Ok(devices)
            })
            .await?
    }
}

pub struct Device {
    inner: MatrixDevice,
}

impl Device {
    pub(crate) fn new(inner: MatrixDevice) -> Self {
        Self { inner }
    }

    pub fn was_verified(&self) -> bool {
        self.inner.verified()
    }

    pub fn get_user_id(&self) -> String {
        self.inner.user_id().to_string()
    }

    pub fn get_device_id(&self) -> String {
        self.inner.device_id().to_string()
    }

    pub fn get_display_name(&self) -> Option<String> {
        self.inner.display_name().map(|s| s.to_owned())
    }
}

pub fn handle_devices_changed_event(client: &Client, tx: &mut Sender<DevicesChangedEvent>) {
    let evt = DevicesChangedEvent::new(client);
    if let Err(e) = tx.try_send(evt) {
        log::warn!("Dropping devices changed event: {}", e);
    }
}
