use chrono::Duration;
use minijinja::{value::Value, Error, ErrorKind};
use std::time::SystemTime;

use crate::events::UtcDateTime;

use super::values::UtcDateTimeValue;

/// create a date using the current date time
pub fn now() -> Value {
    Value::from_struct_object(UtcDateTimeValue::new(UtcDateTime::from(SystemTime::now())))
}

/// create a date in the future add `days`, `weeks`, `hours`, `mins`, `secs` (or any combinations of them) to create
/// a date in the future. Example:
/// ```no_run
///     {{ future(weeks=3, days=4, hours=20, mins=10)}}
/// ```
pub fn future(kwargs: Value) -> Result<Value, Error> {
    let date = UtcDateTime::from(SystemTime::now());
    let mut duration = Duration::zero();
    if let Some(Ok(days)) = kwargs
        .get_attr("days")
        .ok()
        .filter(|x| !x.is_undefined())
        .and_then(|f| f.as_str().map(str::parse::<i64>))
    {
        duration = duration
            .checked_add(&Duration::days(days))
            .ok_or_else(|| Error::new(ErrorKind::InvalidOperation, "days couldn't be added"))?;
    }

    if let Some(Ok(weeks)) = kwargs
        .get_attr("weeks")
        .ok()
        .filter(|x| !x.is_undefined())
        .and_then(|f| f.as_str().map(str::parse::<i64>))
    {
        duration = duration
            .checked_add(&Duration::weeks(weeks))
            .ok_or_else(|| Error::new(ErrorKind::InvalidOperation, "weeks couldn't be added"))?;
    }

    if let Some(Ok(hours)) = kwargs
        .get_attr("hours")
        .ok()
        .filter(|x| !x.is_undefined())
        .and_then(|f| f.as_str().map(str::parse::<i64>))
    {
        duration = duration
            .checked_add(&Duration::hours(hours))
            .ok_or_else(|| Error::new(ErrorKind::InvalidOperation, "hours couldn't be added"))?;
    }

    if let Some(Ok(minutes)) = kwargs
        .get_attr("mins")
        .ok()
        .filter(|x| !x.is_undefined())
        .and_then(|f| f.as_str().map(str::parse::<i64>))
    {
        duration = duration
            .checked_add(&Duration::minutes(minutes))
            .ok_or_else(|| Error::new(ErrorKind::InvalidOperation, "minutes couldn't be added"))?;
    }

    if let Some(Ok(seconds)) = kwargs
        .get_attr("secs")
        .ok()
        .filter(|x| !x.is_undefined())
        .and_then(|f| f.as_str().map(str::parse::<i64>))
    {
        duration = duration
            .checked_add(&Duration::seconds(seconds))
            .ok_or_else(|| Error::new(ErrorKind::InvalidOperation, "seconds couldn't be added"))?;
    }
    Ok(Value::from_struct_object(UtcDateTimeValue::new(
        date + duration,
    )))
}
