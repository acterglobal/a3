use std::sync::Arc;

use acter_matrix::client;

use super::client::UniffiClient;
use crate::api::Client;
use std::os::raw::c_void;

#[no_mangle]
pub extern "C" fn acter_support_ffigen_client_to_uniffi_client(client_ref: isize) -> *const c_void {
    // manually convert the pointer to a Client, then wrap it into a uniffi client in an Arc
    let client = unsafe { &mut *(client_ref as *mut Client) };
    let uniffi_client = UniffiClient::wrap(client.clone());
    Arc::into_raw(Arc::new(uniffi_client)) as *const c_void
}
