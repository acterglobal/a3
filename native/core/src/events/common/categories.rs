use super::Display;
use derive_builder::Builder;
use ruma_events::{EventContent, PossiblyRedactedStateEventContent, StateEventType};
use ruma_macros::EventContent;
use serde::{Deserialize, Serialize};

/// The possibly redacted form of [`CategoriesEventContent`].
///
/// This type is used when it's not obvious whether the content is redacted or not.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[allow(clippy::exhaustive_structs)]
pub struct PossiblyRedactedCategoriesStateEventContent();

impl EventContent for PossiblyRedactedCategoriesStateEventContent {
    type EventType = StateEventType;

    fn event_type(&self) -> Self::EventType {
        "global.acter.category".into()
    }
}

impl PossiblyRedactedStateEventContent for PossiblyRedactedCategoriesStateEventContent {
    type StateKey = String;
}

#[derive(Debug, Serialize, Deserialize, Clone, EventContent)]
#[ruma_event(type = "global.acter.category", kind = State, state_key_type = String, custom_possibly_redacted)]
pub struct CategoriesStateEventContent {
    pub categories: Vec<Category>,
}

#[derive(Debug, Clone, Serialize, Eq, PartialEq, Deserialize, Builder)]
pub struct Category {
    pub id: String,
    pub title: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    #[builder(default, setter(name = "display_typed"))]
    pub display: Option<Display>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    #[builder(default)]
    pub entries: Vec<String>,
}

impl Category {
    pub fn id(&self) -> String {
        self.id.clone()
    }
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
            .id(self.id.clone())
            .title(self.title.clone())
            .display_typed(self.display.clone())
            .to_owned()
    }
}

impl CategoryBuilder {
    pub fn clear_entries(&mut self) {
        self.entries = Some(Vec::new())
    }
    pub fn add_entry(&mut self, entry: String) {
        match self.entries.as_mut() {
            Some(i) => i.push(entry),
            None => {
                self.entries = Some(vec![entry]);
            }
        }
    }
    pub fn unset_display(&mut self) {
        self.display_typed(None);
    }

    #[allow(clippy::boxed_local)]
    pub fn display(&mut self, display: Box<Display>) {
        self.display_typed(Some(*display));
    }
}
