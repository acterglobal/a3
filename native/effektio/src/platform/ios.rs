use anyhow::Result;
use matrix_sdk::ClientBuilder;

use super::native;

pub async fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    let builder = native::new_client_config(base_path, home)
        .await?
        .user_agent(format!("effektio-ios/{:}", env!("CARGO_PKG_VERSION")));
    Ok(builder)
}

pub fn init_logging(filter: Option<String>) -> Result<String> {
    // FIXME: not yet supported
    let file_path = "".to_string();
    Ok(file_path)
}
