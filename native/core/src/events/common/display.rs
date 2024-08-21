use derive_builder::Builder;
use serde::{Deserialize, Serialize};

use super::{Color, Icon};

#[derive(Clone, Debug, Deserialize, PartialEq, Eq, Serialize, Builder)]
#[builder(name = "DisplayBuilder", derive(Debug))]
pub struct Display {
    /// Colorize the item
    #[builder(setter(into, name = "color_typed"), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub color: Option<Color>,

    /// Show this icon
    #[builder(setter(into, name = "icon_typed"), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub icon: Option<Icon>,
}

impl Display {
    pub fn color(&self) -> Option<u32> {
        self.color
    }
    pub fn icon_type_str(&self) -> Option<String> {
        self.icon.as_ref().map(|i| i.icon_type_str())
    }
    pub fn icon_str(&self) -> Option<String> {
        self.icon.as_ref().map(|i| i.icon_str())
    }

    pub fn update_builder(&self) -> DisplayBuilder {
        DisplayBuilder::default()
            .color_typed(self.color)
            .icon_typed(self.icon.clone())
            .to_owned()
    }
}

impl DisplayBuilder {
    pub fn color(&mut self, value: u32) {
        self.color_typed(value);
    }

    pub fn unset_color(&mut self) {
        self.color_typed(None);
    }

    pub fn icon(&mut self, typ: String, value: String) {
        self.icon_typed(Icon::parse(typ, value));
    }
    pub fn unset_icon(&mut self) {
        self.icon_typed(None);
    }
}
