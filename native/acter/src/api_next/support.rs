

use std::sync::Arc;

use acter_core::client;

use crate::api::{Client};
use super::client::UniffiClient;


#[no_mangle]
pub extern "C" fn to_client_ref(client_ref: isize) -> UniffiClient {
    let client = unsafe { &mut *(client_ref as *mut Client) };
    UniffiClient { client: Arc::new(client.clone()) }
}
