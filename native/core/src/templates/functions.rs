use super::values::UtcDateTimeValue;
use crate::events::UtcDateTime;
use chrono::Duration;
use minijinja::{value::Value, Error, ErrorKind};
use std::time::SystemTime;

pub fn now() -> Value {
    Value::from_struct_object(UtcDateTimeValue::new(UtcDateTime::from(SystemTime::now())))
}

pub fn future(
    add_days: Option<i64>,
    add_weeks: Option<i64>,
    add_hours: Option<i64>,
    add_mins: Option<i64>,
    add_secs: Option<i64>,
) -> Result<Value, Error> {
    let date = UtcDateTime::from(SystemTime::now());
    let mut duration = Duration::zero();
    if let Some(days) = add_days {
        duration = duration
            .checked_add(&Duration::days(days))
            .ok_or_else(|| Error::new(ErrorKind::InvalidOperation, "days couldn't be added"))?;
    }

    if let Some(weeks) = add_weeks {
        duration = duration
            .checked_add(&Duration::weeks(weeks))
            .ok_or_else(|| Error::new(ErrorKind::InvalidOperation, "weeks couldn't be added"))?;
    }

    if let Some(hours) = add_hours {
        duration = duration
            .checked_add(&Duration::hours(hours))
            .ok_or_else(|| Error::new(ErrorKind::InvalidOperation, "hours couldn't be added"))?;
    }

    if let Some(minutes) = add_mins {
        duration = duration
            .checked_add(&Duration::minutes(minutes))
            .ok_or_else(|| Error::new(ErrorKind::InvalidOperation, "minutes couldn't be added"))?;
    }

    if let Some(seconds) = add_secs {
        duration = duration
            .checked_add(&Duration::seconds(seconds))
            .ok_or_else(|| Error::new(ErrorKind::InvalidOperation, "seconds couldn't be added"))?;
    }
    Ok(Value::from_struct_object(UtcDateTimeValue::new(
        date + duration,
    )))
}
