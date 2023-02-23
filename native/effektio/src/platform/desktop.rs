use anyhow::Result;
use env_logger::filter::Builder as FilterBuilder;
use log::LevelFilter;
use matrix_sdk::ClientBuilder;
use reqwest::{
    blocking::{
        multipart::{Form, Part},
        Client,
    },
    StatusCode,
};
use std::{fs::canonicalize, path::PathBuf, sync::Arc};

use super::native;

pub use super::native::sanitize;

pub async fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    let builder = native::new_client_config(base_path, home)
        .await?
        .user_agent(format!(
            "{:}/effektio@{:}",
            option_env!("CARGO_BIN_NAME").unwrap_or("effektio-desktop"),
            env!("CARGO_PKG_VERSION")
        ));
    Ok(builder)
}

static mut FILE_LOGGER: Option<Arc<fern::ImplDispatch>> = None;

// this excludes macos, because macos and ios is very much alike in logging

pub fn init_logging(app_name: String, log_dir: String, filter: Option<String>) -> Result<()> {
    std::env::set_var("RUST_BACKTRACE", "1");
    log_panics::init();

    let log_level = match filter {
        Some(filter) => FilterBuilder::new().parse(&filter).build(),
        None => FilterBuilder::new().build(),
    };

    let mut path = PathBuf::from(log_dir.as_str());
    path.push("app_");

    let (level, dispatch) = fern::Dispatch::new()
        .format(|out, message, record| {
            out.finish(format_args!(
                "{}[{}][{}] {}",
                chrono::Local::now().format("[%Y-%m-%d][%H:%M:%S]"),
                record.target(),
                record.level(),
                message
            ))
        })
        .level(log_level.filter())
        .chain(std::io::stdout())
        .chain(fern::Manual::new(path, "%Y-%m-%d_%H-%M-%S%.f.log"))
        .into_dispatch_with_arc();

    if level == log::LevelFilter::Off {
        log::set_boxed_logger(Box::new(native::NopLogger)).unwrap();
    } else {
        log::set_boxed_logger(Box::new(dispatch.clone())).unwrap();
    }
    log::set_max_level(level);

    unsafe {
        FILE_LOGGER = Some(dispatch);
    }

    Ok(())
}

pub fn report_bug(text: String, label: String) -> Result<bool> {
    unsafe {
        if let Some(dispatch) = &FILE_LOGGER {
            let res = dispatch.rotate();
            for output in res.iter() {
                match output {
                    Some((old_path, new_path)) => {
                        let log_path = canonicalize(old_path)?.to_string_lossy().to_string();
                        // submit bug report to rageserver to open issue for that bug
                        let form = Form::new()
                            .text("text", text.clone())
                            .text("user_agent", "Mozilla/0.9")
                            .text("app", "Effektio-windows")
                            .text("version", "1.0.0")
                            .text("label", label.clone())
                            .file("log", log_path.clone())?;
                        let resp = Client::new()
                            .post("http://192.168.142.130:9110/api/submit")
                            .basic_auth("alice", Some("secret"))
                            .multipart(form)
                            .send()?;
                        return Ok(resp.status() == StatusCode::OK);
                    }
                    None => {}
                }
            }
        }
    }
    Ok(false)
}
