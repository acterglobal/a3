use crate::Result;
pub use csscolorparser::Color;
use derive_getters::Getters;
use ruma_events::room::ImageInfo;
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
#[derive(Clone, Debug, Getters, Deserialize, Serialize, Default)]
pub struct Colorize {
    /// The foreground color to be used, as HEX
    color: Option<Color>,
    /// The background color to be used, as HEX
    background: Option<Color>,
}

#[derive(Debug, Clone, Default)]
pub struct ColorizeBuilder {
    colorize: Colorize,
}

impl ColorizeBuilder {
    pub fn color_from_html(&mut self, color: String) -> Result<bool> {
        let color = Color::from_html(color)?;
        self.colorize.color = Some(color);
        Ok(true)
    }

    pub fn background_from_html(&mut self, color: String) -> Result<bool> {
        let color = Color::from_html(color)?;
        self.colorize.background = Some(color);
        Ok(true)
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
