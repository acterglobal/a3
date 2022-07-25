use lazy_static::lazy_static;
use tokio::runtime;

lazy_static! {
    static ref RUNTIME: runtime::Runtime =
        runtime::Runtime::new().expect("Can't start Tokio runtime");
}

mod devices_changed;
mod emoji_verification;

pub use devices_changed::*;
pub use emoji_verification::*;
