mod native;

#[cfg(target_os = "android")]
mod android;

#[cfg(target_os = "android")]
pub use android::*;

#[cfg(any(target_os = "ios", target_os = "macos"))]
mod ios;

#[cfg(any(target_os = "ios", target_os = "macos"))]
pub use ios::*;

#[cfg(not(any(target_os = "android", target_os = "ios", target_os = "macos")))]
mod desktop;
#[cfg(not(any(target_os = "android", target_os = "ios", target_os = "macos")))]
pub use desktop::*;

pub use native::{report_bug, sanitize, write_log};
