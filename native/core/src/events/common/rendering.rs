pub use csscolorparser::Color;
use derive_getters::Getters;
use ruma_events::room::ImageInfo;
use serde::{Deserialize, Serialize};
use std::str::FromStr;
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

impl FromStr for Position {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "top-left" => Ok(Position::TopLeft),
            "top-middle" => Ok(Position::TopMiddle),
            "top-right" => Ok(Position::TopRight),
            "center-left" => Ok(Position::CenterLeft),
            "center-middle" => Ok(Position::CenterMiddle),
            "center-right" => Ok(Position::CenterRight),
            "bottom-left" => Ok(Position::BottomLeft),
            "bottom-middle" => Ok(Position::BottomMiddle),
            "bottom-right" => Ok(Position::BottomRight),
            _ => Err(()),
        }
    }
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
