use matrix_sdk_base::ruma::events::macros::EventContent;
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

pub static BOOKMARKS_KEY: &str = "global.acter.bookmarks";

#[derive(Debug, Serialize, Default, Deserialize, Clone, EventContent)]
#[ruma_event(type = "global.acter.bookmarks", kind = GlobalAccountData)]
pub struct BookmarksEventContent {
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub pins: Vec<String>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub tasks: Vec<String>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub task_lists: Vec<String>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub events: Vec<String>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub news: Vec<String>,

    #[serde(default, skip_serializing_if = "BTreeMap::is_empty")]
    #[serde(flatten)]
    pub other: BTreeMap<String, Vec<String>>,
}
