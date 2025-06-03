use super::Display;
use derive_builder::Builder;
use matrix_sdk_base::ruma::events::macros::EventContent;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone, EventContent)]
#[ruma_event(type = "global.acter.category", kind = State, state_key_type = String)]
pub struct CategoriesStateEventContent {
    pub categories: Vec<Category>,
}

#[derive(Debug, Clone, Serialize, Eq, PartialEq, Deserialize, Builder)]
pub struct Category {
    pub title: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    #[builder(default, setter(name = "display_typed"))]
    pub display: Option<Display>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    #[builder(default)]
    pub entries: Vec<String>,
}

impl Category {
    pub fn title(&self) -> String {
        self.title.clone()
    }

    pub fn entries(&self) -> Vec<String> {
        self.entries.clone()
    }

    pub fn display(&self) -> Option<Display> {
        self.display.clone()
    }

    pub fn update_builder(&self) -> CategoryBuilder {
        CategoryBuilder::default()
            .entries(self.entries())
            .title(self.title.clone())
            .display_typed(self.display.clone())
            .to_owned()
    }
}

impl CategoryBuilder {
    pub fn clear_entries(&mut self) {
        self.entries = Some(Vec::new());
    }

    pub fn add_entry(&mut self, entry: String) {
        match self.entries.as_mut() {
            Some(i) => i.push(entry),
            None => {
                self.entries = Some(vec![entry]);
            }
        };
    }

    pub fn unset_display(&mut self) {
        self.display_typed(None);
    }

    #[allow(clippy::boxed_local)]
    pub fn display(&mut self, display: Box<Display>) {
        self.display_typed(Some(*display));
    }
}
