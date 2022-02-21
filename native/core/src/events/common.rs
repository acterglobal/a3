use matrix_sdk::ruma::events::macros::EventContent;
use serde::{Deserialize, Serialize};

/// Customize the color scheme
#[derive(Clone, Debug, Deserialize, Serialize, EventContent)]
#[ruma_event(type = "org.effektio.dev.colors")]
pub struct Colorize {
    /// The foreground color to be used, as HEX
    pub color: Option<String>,
    /// The background color to be used, as HEX
    pub background: Option<String>,
}
