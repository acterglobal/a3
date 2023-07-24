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

#[cfg(feature = "video-meta")]
pub use native::{parse_video, VideoMetadata};
pub use native::{rotate_log_file, sanitize, write_log};
