use super::color::Color;
use ruma_events::room::ImageInfo;
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use strum::{Display, EnumString};

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

#[derive(Clone, Debug, Deserialize, Serialize, EnumString, Display)]
#[serde(rename_all = "kebab-case")]
#[strum(serialize_all = "kebab-case")]
pub enum BrandLogo {
    Discord,
    Email,
    Facebook,
    Ferdiverse,
    Figma,
    Github,
    Gitlab,
    Googledrive,
    Googleplay,
    Instagram,
    Jitsi,
    Linkedin,
    Matrix,
    Mastodon,
    Medium,
    Meta,
    Notion,
    Reddit,
    Slack,
    Skype,
    Snapchat,
    #[serde(alias = "stackoverflow", alias = "stack-overflow")]
    StackOverflow,
    Telegram,
    Twitter,
    Whatsapp,
    Wechat,
    Youtube,
    X,
    Zoom,
    Custom(String),
    // FIXME: support for others?
}

#[derive(Clone, Debug, Deserialize, Serialize, EnumString, Display)]
#[serde(rename_all = "kebab-case")]
#[strum(serialize_all = "kebab-case")]
pub enum ActerIcon {
    // subset of https://phosphoricons.com
    Acorn,
    Alien,
    Ambulance,
    Anchor,
    Archive,
    Armchair,
    Axe,
    Backpack,
    Balloon,
    Binoculars,
    Bird,
    Fire,
    Flower,
    FlowerLotus,
    FlowerTulip,
    GameController,
    Ghost,
    Globe,
    Guitar,
    Heart,
    HeartBeat,
    Home,
    Island,
    Lego,
    LegoSmile,
    Megaphone,
    Newspaper,
    Rocket,
    RocketLaunch,
    Custom(String),
    // FIXME: support for others?
}

/// Customize the color scheme
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(tag = "type", rename_all = "kebab-case")]
pub enum Icon {
    Emoji { key: String },
    BrandLogo { icon: BrandLogo },
    ActerIcon { icon: ActerIcon },
    Image(ImageInfo),
}

impl Icon {
    pub fn icon_type_str(&self) -> String {
        match self {
            Icon::Emoji { .. } => "emoji".to_owned(),
            Icon::BrandLogo { .. } => "brand-logo".to_owned(),
            Icon::ActerIcon { .. } => "acter-icon".to_owned(),
            Icon::Image(_) => "image".to_owned(),
        }
    }
    pub fn icon_str(&self) -> String {
        match self {
            Icon::Emoji { key } => key.clone(),
            Icon::BrandLogo { icon } => icon.to_string(),
            Icon::ActerIcon { icon } => icon.to_string(),
            Icon::Image(_) => "image".to_owned(),
        }
    }
}
