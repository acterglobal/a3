use anyhow::{bail, Result};
use lazy_static::lazy_static;
use log::{Log, Metadata, Record};
use matrix_sdk::{Client, ClientBuilder};
use matrix_sdk_sled::make_store_config;
use reqwest::{
    multipart::{Form, Part},
    Client as ReqClient, StatusCode,
};
use serde::Deserialize;
use std::{
    path::PathBuf,
    sync::{Arc, Mutex},
};
use tokio::fs::File;

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

#[derive(Deserialize)]
struct ReportResp {
    report_url: String, // example - https://github.com/bitfriend/effektio-bugs/issues/9
}

#[allow(clippy::too_many_arguments)]
pub async fn report_bug(
    url: String,
    username: String,
    password: Option<String>,
    app_name: String,
    version: String,
    description: String,
    tag: Option<String>,
    with_log: bool,
    screenshot_path: Option<String>,
) -> Result<String> {
    let mut form = Form::new()
        .text("text", description)
        .text("user_agent", "Mozilla/0.9")
        .text("app", app_name)
        .text("version", version);
    if let Some(tag) = tag {
        form = form.text("label", tag);
    }
    let old_path = if with_log {
        let mut res = None;
        match &*FILE_LOGGER.lock().unwrap() {
            Some(dispatch) => {
                for output in dispatch.rotate().iter() {
                    match output {
                        Some((old_path, new_path)) => {
                            res = Some(old_path.clone());
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
        res
    } else {
        None
    };
    RUNTIME
        .spawn(async move {
            // call await, after lock is released
            // if await is called under lock exists, you will get deadlock
            if let Some(old_path) = old_path {
                let log_path = old_path.canonicalize()?.to_string_lossy().to_string();
                let file = File::open(log_path).await?;
                let length = file.metadata().await?.len();
                let filename = old_path.file_name().unwrap().to_string_lossy().to_string();
                let file_part = Part::stream_with_length(file, length)
                    .file_name(filename)
                    .mime_str("text/plain")?;
                form = form.part("log", file_part);
            }
            if let Some(screenshot_path) = screenshot_path {
                let mut file = File::open(&screenshot_path).await?;
                let length = file.metadata().await?.len();
                let file_path = PathBuf::from(&screenshot_path);
                let filename = file_path.file_name().unwrap().to_string_lossy().to_string();
                let file_part = Part::stream_with_length(file, length)
                    .file_name(filename)
                    .mime_str("image/png")?;
                form = form.part("file", file_part);
            }
            let resp = ReqClient::new()
                .post(url)
                .basic_auth(username, password)
                .multipart(form)
                .send()
                .await?;
            log::info!("report error: {:?}", resp);
            if resp.status() == StatusCode::OK {
                let json = resp.json::<ReportResp>().await?;
                Ok(json.report_url)
            } else {
                Ok("".to_string())
            }
        })
        .await?
}

pub fn write_log(text: String, level: String) -> Result<()> {
    match level.as_str() {
        "debug" => log::debug!("{}", text),
        "error" => log::error!("{}", text),
        "info" => log::info!("{}", text),
        "warn" => log::warn!("{}", text),
        "trace" => log::trace!("{}", text),
        _ => {}
    }
    Ok(())
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
