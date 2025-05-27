use chrono::NaiveDate;
use matrix_sdk_base::ruma::events::room::message::TextMessageEventContent;
use serde::{Deserialize, Serialize};

use crate::events::UtcDateTime;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct TitleContent {
    change: String,
    new_val: String,
}

impl TitleContent {
    pub fn new(change: String, new_val: String) -> Self {
        Self { change, new_val }
    }

    pub fn change(&self) -> String {
        self.change.clone()
    }

    pub fn new_val(&self) -> String {
        self.new_val.clone()
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct DescriptionContent {
    change: String,
    pub new_val: Option<TextMessageEventContent>,
}

impl DescriptionContent {
    pub fn new(change: String, new_val: Option<TextMessageEventContent>) -> Self {
        Self { change, new_val }
    }

    pub fn change(&self) -> String {
        self.change.clone()
    }

    pub fn new_val(&self) -> Option<String> {
        self.new_val.as_ref().map(|c| c.body.clone())
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct DateContent {
    change: String,
    new_val: Option<NaiveDate>,
}

impl DateContent {
    pub fn new(change: String, new_val: Option<NaiveDate>) -> Self {
        Self { change, new_val }
    }

    pub fn change(&self) -> String {
        self.change.clone()
    }

    pub fn new_val(&self) -> Option<String> {
        self.new_val
            .as_ref()
            .map(|d| d.format("%Y-%m-%d").to_string())
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct DateTimeRangeContent {
    start_new_val: Option<UtcDateTime>,
    end_new_val: Option<UtcDateTime>,
}

impl DateTimeRangeContent {
    pub fn new(start_new_val: Option<UtcDateTime>, end_new_val: Option<UtcDateTime>) -> Self {
        Self {
            start_new_val,
            end_new_val,
        }
    }

    pub fn start_new_val(&self) -> Option<UtcDateTime> {
        self.start_new_val
    }

    pub fn end_new_val(&self) -> Option<UtcDateTime> {
        self.end_new_val
    }
}
