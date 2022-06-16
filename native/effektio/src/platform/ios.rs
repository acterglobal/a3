use anyhow::Result;
use matrix_sdk::ClientBuilder;

use super::native;

pub fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    Ok(native::new_client_config(base_path, home)?.user_agent("effektio-android"))
}

pub fn init_logging(filter: Option<String>) -> Result<()> {
    // FIXME: not yet supported

    Ok(())
}
