mod event;

pub use event::{CalendarEvent, CalendarEventUpdate};

use crate::statics::KEYS;

static CALENDAR_KEY: &str = KEYS::CALENDAR;
