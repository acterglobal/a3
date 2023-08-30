pub use csscolorparser::Color;
use derive_getters::Getters;
use matrix_sdk::ruma::events::room::ImageInfo;
use serde::{Deserialize, Serialize};
use strum::Display;

#[derive(Clone, Debug, Display, Deserialize, Serialize, Default)]
#[serde(rename_all = "kebab-case")]
pub enum Position {
    TopLeft,
    TopMiddle,
    TopRight,
    CenterLeft,
    CenterMiddle,
    CenterRight,
    BottomLeft,
    #[default]
    BottomMiddle,
    BottomRight,
}

/// Customize the color scheme
#[derive(Clone, Debug, Getters, Deserialize, Serialize)]
pub struct Colorize {
    /// The foreground color to be used, as HEX
    color: Option<Color>,
    /// The background color to be used, as HEX
    background: Option<Color>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum BrandIcon {
    Matrix,
    Twitter,
    Facebook,
    Email,
    Youtube,
    Whatsapp,
    Reddit,
    Skype,
    Zoom,
    Jitsi,
    Telegram,
    GoogleDrive,
    Custom(String),
    // FIXME: support for others?
}

/// Customize the color scheme
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(tag = "type")]
pub enum Icon {
    Emoji { key: String },
    BrandIcon { icon: BrandIcon },
    Image(ImageInfo),
}
