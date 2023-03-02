use anyhow::{bail, Result};
use lazy_static::lazy_static;
use log::{Log, Metadata, Record};
use matrix_sdk::{Client, ClientBuilder};
use matrix_sdk_sled::make_store_config;
use reqwest::{
    multipart::{Form, Part},
    Client as ReqClient, StatusCode,
};
use std::{
    fs,
    path::PathBuf,
    sync::{Arc, Mutex},
};

use super::super::api::RUNTIME;

pub async fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    let data_path = sanitize(base_path, home);

    std::fs::create_dir_all(&data_path)?;

    let builder = Client::builder()
        .store_config(make_store_config(&data_path, None).await?)
        .user_agent(format!("effektio-testing/{:}", env!("CARGO_PKG_VERSION")));
    Ok(builder)
}

lazy_static! {
    pub static ref FILE_LOGGER: Mutex<Option<Arc<fern::ImplDispatch>>> = Mutex::new(None);
}

pub fn init_logging(log_dir: String, filter: Option<String>) -> Result<()> {
    Ok(())
}

#[allow(clippy::too_many_arguments)]
pub async fn report_bug(
    url: String,
    username: String,
    password: Option<String>,
    app_name: String,
    version: String,
    text: String,
    label: String,
    with_log: bool,
    screenshot_path: Option<String>,
) -> Result<bool> {
    let mut form = Form::new()
        .text("text", text)
        .text("user_agent", "Mozilla/0.9")
        .text("app", app_name)
        .text("version", version)
        .text("label", label);
    if let Some(screenshot_path) = screenshot_path {
        let file_path = PathBuf::from(&screenshot_path);
        let img_path = file_path.canonicalize()?.to_string_lossy().to_string();
        let file = fs::read(img_path)?;
        let filename = file_path.file_name().unwrap().to_string_lossy().to_string();
        let file_part = Part::bytes(file)
            .file_name(filename)
            .mime_str("image/png")?;
        form = form.part("file", file_part);
    }
    if with_log {
        match &*FILE_LOGGER.lock().unwrap() {
            Some(dispatch) => {
                let res = dispatch.rotate();
                for output in res.iter() {
                    match output {
                        Some((old_path, new_path)) => {
                            let log_path = old_path.canonicalize()?.to_string_lossy().to_string();
                            let file = fs::read(log_path)?;
                            let filename =
                                old_path.file_name().unwrap().to_string_lossy().to_string();
                            let file_part = Part::bytes(file)
                                .file_name(filename)
                                .mime_str("text/plain")?;
                            form = form.part("log", file_part);
                            break;
                        }
                        None => {}
                    }
                }
            }
            None => {
                bail!("You didn't set up file logger.");
            }
        }
    }
    RUNTIME
        .spawn(async move {
            let resp = ReqClient::new()
                .post(url)
                .basic_auth(username, password)
                .multipart(form)
                .send()
                .await?;
            Ok(resp.status() == StatusCode::OK)
        })
        .await?
}

pub fn sanitize(base_path: String, home: String) -> PathBuf {
    PathBuf::from(base_path).join(sanitize_filename_reader_friendly::sanitize(&home))
}

pub struct NopLogger;

impl Log for NopLogger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        false
    }

    fn log(&self, record: &Record) {}

    fn flush(&self) {}
}
