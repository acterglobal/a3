use super::color::Color;
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
    type Err = crate::Error;

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
            _ => Err(crate::Error::FailedToParse {
                model_type: "Position".to_owned(),
                msg: format!("{s} is not a valid Position"),
            }),
        }
    }
}

/// Customize the color scheme
#[derive(Clone, Debug, Deserialize, Serialize, Default)]
pub struct Colorize {
    /// The foreground color to be used, as HEX
    color: Option<Color>,
    /// The background color to be used, as HEX
    background: Option<Color>,
}

impl Colorize {
    pub fn color(&self) -> Option<Color> {
        self.color
    }
    pub fn background(&self) -> Option<Color> {
        self.background
    }
}

#[derive(Debug, Clone, Default)]
pub struct ColorizeBuilder {
    colorize: Colorize,
}

impl ColorizeBuilder {
    pub fn color(&mut self, color: u32) {
        self.colorize.color = Some(color);
    }

    pub fn background(&mut self, color: u32) {
        self.colorize.background = Some(color);
    }

    pub fn unset_color(&mut self) {
        self.colorize.color = None;
    }

    pub fn unset_background(&mut self) {
        self.colorize.background = None;
    }

    pub fn build(self) -> Option<Colorize> {
        let ColorizeBuilder { colorize } = self;
        if colorize.color.is_some() || colorize.background.is_some() {
            return Some(colorize);
        }
        None
    }
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
