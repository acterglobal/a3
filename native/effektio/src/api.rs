#![allow(clippy::missing_safety_doc, clippy::not_unsafe_ptr_arg_deref)]


use anyhow::{Context, Result};
use lazy_static::lazy_static;
use matrix_sdk::Client as MatrixClient;
use parking_lot::RwLock;
use std::{collections::BTreeMap, io};
use tokio::runtime::{Builder, Runtime};

lazy_static! {
    static ref RUNTIME: io::Result<Runtime> = Builder::new_multi_thread()
        .worker_threads(4)
        .thread_name("effektiorust")
        .build();
    static ref CLIENTS: RwLock<BTreeMap<u32, MatrixClient>> = RwLock::new(BTreeMap::new());
    static ref CLIENTS_COUNTER: RwLock<u32> = RwLock::new(0);
}


#[derive(Debug, Clone)]
pub struct Client(pub(crate) u32);

impl Client {
    fn matrix_client(&self) -> Result<MatrixClient, anyhow::Error> {
        let lock = CLIENTS.read();
        lock.get(&self.0).context("Client unknown").map(|m| m.clone())
    }
}

pub async fn avatar_url(h: Client) -> Result<Option<String>> {
    Ok(match h.matrix_client()?.avatar_url().await? {
        Some(u) => Some(u.to_string()),
        None => None
    })
}
pub async fn logged_in(h: Client) -> Result<bool> {
    Ok(h.matrix_client()?.logged_in().await)
}
pub async fn homeserver(h: Client) -> Result<String> {
    Ok(h.matrix_client()?.homeserver().await.to_string())
}
pub async fn login(
    h: Client,
    user: String,
    password: String,
    device_id: Option<String>,
    initial_device_display_name: Option<&str>
) -> Result<String> {
    let m = h.matrix_client()?;
    let r = m.login(&user, &password, device_id, initial_device_display_name)?;

}

/// Returns 0 if things went wrong, or the reference number otherwise
pub fn new_client(url: String) -> Result<Client> {
    let url = url.parse()?;
    let counter = CLIENTS_COUNTER
        .read()
        .checked_add(1)
        .context("Running out of clients")?;
    {
        let client = MatrixClient::new(url)?;
        (*CLIENTS.write()).insert(counter, client);
    }
    *CLIENTS_COUNTER.write() = counter;
    Ok(Client(counter))
}

pub async fn echo(url: String) -> Result<String> {
    async move {
        Ok(url)
    }.await
}

pub fn init() -> Result<()> {
    const LOGGER: cute_log::Logger = cute_log::Logger::new();
    LOGGER.set_max_level(cute_log::log::LevelFilter::Info);
    //error!(LOGGER.set_LOGGER());
    Ok(())
}
