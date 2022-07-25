use lazy_static::lazy_static;
use tokio::runtime;

lazy_static! {
    static ref RUNTIME: runtime::Runtime =
        runtime::Runtime::new().expect("Can't start Tokio runtime");
}

mod device;
mod emoji_verification;

pub use device::*;
pub use emoji_verification::*;
