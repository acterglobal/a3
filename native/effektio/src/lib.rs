#![allow(clippy::missing_safety_doc, clippy::not_unsafe_ptr_arg_deref)]

use allo_isolate::Isolate;
use anyhow::Context;
use ffi_helpers::null_pointer_check;
use lazy_static::lazy_static;
use matrix_sdk::Client;
use parking_lot::RwLock;
use std::{collections::BTreeMap, ffi::CStr, io, os::raw};
use tokio::runtime::{Builder, Runtime};

lazy_static! {
    static ref RUNTIME: io::Result<Runtime> = Builder::new_multi_thread()
        .worker_threads(4)
        .thread_name("effektiorust")
        .build();
    static ref CLIENTS: RwLock<BTreeMap<i32, Client>> = RwLock::new(BTreeMap::new());
    static ref CLIENTS_COUNTER: RwLock<i32> = RwLock::new(0);
}

macro_rules! error {
    ($result:expr) => {
        error!($result, 0);
    };
    ($result:expr, $error:expr) => {
        match $result {
            Ok(value) => value,
            Err(e) => {
                ffi_helpers::update_last_error(e);
                return $error;
            }
        }
    };
}

macro_rules! cstr {
    ($ptr:expr) => {
        cstr!($ptr, 0);
    };
    ($ptr:expr, $error:expr) => {{
        null_pointer_check!($ptr);
        error!(unsafe { CStr::from_ptr($ptr).to_str() }, $error)
    }};
}

macro_rules! runtime {
    () => {
        match RUNTIME.as_ref() {
            Ok(rt) => rt,
            Err(_) => {
                return 0;
            }
        }
    };
}

macro_rules! allo_async {
    ($port:expr, $call:expr) => {{
        let rt = runtime!();
        let t = Isolate::new($port).task($call);
        rt.spawn(t);
        1
    }};
}

#[no_mangle]
pub unsafe extern "C" fn last_error_length() -> i32 {
    ffi_helpers::error_handling::last_error_length()
}

#[no_mangle]
pub unsafe extern "C" fn error_message_utf8(buf: *mut raw::c_char, length: i32) -> i32 {
    ffi_helpers::error_handling::error_message_utf8(buf, length)
}

#[no_mangle]
/// Returns 0 if things went wrong, or the reference number otherwise
pub extern "C" fn new_client(url: *const raw::c_char) -> i32 {
    let url = error!(cstr!(url).parse());
    let counter = error!(CLIENTS_COUNTER
        .read()
        .checked_add(1)
        .context("Running out of clients"));
    {
        let client = error!(Client::new(url));
        (*CLIENTS.write()).insert(counter, client);
    }
    *CLIENTS_COUNTER.write() = counter;
    counter
}

#[no_mangle]
pub extern "C" fn echo(port: i64, url: *const raw::c_char) -> i32 {
    let url = cstr!(url);
    println!("in echo");
    allo_async!(port, async move {
        url
    })
}

#[no_mangle]
pub extern "C" fn init() -> i32 {
    const LOGGER: cute_log::Logger = cute_log::Logger::new();
    LOGGER.set_max_level(cute_log::log::LevelFilter::Info);
    //error!(LOGGER.set_LOGGER());
    1
}
