mod native;

#[cfg(target_os = "android")]
mod android;

#[cfg(target_os = "android")]
pub use android::*;

#[cfg(target_os = "ios")]
mod ios;

#[cfg(target_os = "ios")]
pub use ios::*;

#[cfg(not(any(target_os = "android", target_os = "ios")))]
mod desktop;
#[cfg(not(any(target_os = "android", target_os = "ios")))]
pub use desktop::*;
