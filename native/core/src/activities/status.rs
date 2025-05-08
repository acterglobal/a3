use chrono::NaiveDate;
use matrix_sdk_base::ruma::events::room::message::TextMessageEventContent;
use serde::{Deserialize, Serialize};

use crate::events::UtcDateTime;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct TitleContent {
    content: String,
    prev_content: Option<String>,
}

impl TitleContent {
    pub fn new(content: String, prev_content: Option<String>) -> Self {
        Self {
            content,
            prev_content,
        }
    }

    pub fn change(&self) -> Option<String> {
        if let Some(prev_content) = &self.prev_content {
            if self.content == *prev_content {
                return None;
            } else {
                return Some("Changed".to_owned());
            }
        }
        Some("Set".to_owned())
    }

    pub fn new_val(&self) -> String {
        self.content.clone()
    }

    pub fn old_val(&self) -> Option<String> {
        self.prev_content.clone()
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct DescriptionContent {
    content: TextMessageEventContent,
    prev_content: Option<TextMessageEventContent>,
}

impl DescriptionContent {
    pub fn new(
        content: TextMessageEventContent,
        prev_content: Option<TextMessageEventContent>,
    ) -> Self {
        Self {
            content,
            prev_content,
        }
    }

    pub fn content(&self) -> TextMessageEventContent {
        self.content.clone()
    }

    pub fn change(&self) -> Option<String> {
        if let Some(prev_content) = &self.prev_content {
            if self.content.body == prev_content.body {
                return None;
            } else {
                return Some("Changed".to_owned());
            }
        }
        Some("Set".to_owned())
    }

    pub fn new_val(&self) -> String {
        self.content.body.clone()
    }

    pub fn old_val(&self) -> Option<String> {
        self.prev_content.as_ref().map(|c| c.body.clone())
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct DateContent {
    content: Option<NaiveDate>,
    prev_content: Option<NaiveDate>,
}

impl DateContent {
    pub fn new(content: Option<NaiveDate>, prev_content: Option<NaiveDate>) -> Self {
        Self {
            content,
            prev_content,
        }
    }

    pub fn change(&self) -> Option<String> {
        match (&self.prev_content, &self.content) {
            (Some(prev_content), Some(content)) => {
                if prev_content == content {
                    return None;
                } else {
                    return Some("Changed".to_owned());
                }
            }
            (None, Some(_)) => Some("Set".to_owned()),
            (Some(_), None) => Some("Unset".to_owned()),
            _ => None,
        }
    }

    pub fn new_val(&self) -> Option<String> {
        self.content
            .as_ref()
            .map(|d| d.format("%Y-%m-%d").to_string())
    }

    pub fn old_val(&self) -> Option<String> {
        self.prev_content
            .as_ref()
            .map(|d| d.format("%Y-%m-%d").to_string())
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct DateTimeRangeContent {
    start: Option<UtcDateTime>,
    end: Option<UtcDateTime>,
    prev_start: Option<UtcDateTime>,
    prev_end: Option<UtcDateTime>,
}

impl DateTimeRangeContent {
    pub fn new(
        start: Option<UtcDateTime>,
        end: Option<UtcDateTime>,
        prev_start: Option<UtcDateTime>,
        prev_end: Option<UtcDateTime>,
    ) -> Self {
        Self {
            start,
            end,
            prev_start,
            prev_end,
        }
    }

    pub fn start_change(&self) -> Option<String> {
        match (&self.prev_start, &self.start) {
            (Some(prev_start), Some(start)) => {
                if prev_start == start {
                    return None;
                } else {
                    return Some("Changed".to_owned());
                }
            }
            (None, Some(_)) => Some("Set".to_owned()),
            (Some(_), None) => Some("Unset".to_owned()),
            _ => None,
        }
    }

    pub fn start_new_val(&self) -> Option<UtcDateTime> {
        self.start.clone()
    }

    pub fn start_old_val(&self) -> Option<UtcDateTime> {
        self.prev_start.clone()
    }

    pub fn end_change(&self) -> Option<String> {
        match (&self.prev_end, &self.end) {
            (Some(prev_end), Some(end)) => {
                if prev_end == end {
                    return None;
                } else {
                    return Some("Changed".to_owned());
                }
            }
            (None, Some(_)) => Some("Set".to_owned()),
            (Some(_), None) => Some("Unset".to_owned()),
            _ => None,
        }
    }

    pub fn end_new_val(&self) -> Option<UtcDateTime> {
        self.end.clone()
    }

    pub fn end_old_val(&self) -> Option<UtcDateTime> {
        self.prev_end.clone()
    }
}
