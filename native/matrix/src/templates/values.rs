use minijinja::value::{Enumerator, Object, Value};
use std::sync::Arc;

use super::Error;
use crate::{client::CoreClient, events::UtcDateTime};

/// Hold a User client
#[derive(Debug)]
pub struct UserValue {
    user_id: String,
    display_name: String,
    _client: Arc<CoreClient>,
}

impl UserValue {
    pub(crate) async fn new(client: Arc<CoreClient>) -> Result<Self, Error> {
        let c = client.client();
        let user_id = c
            .user_id()
            .ok_or(Error::Remap(
                "user".to_owned(),
                "missing user_id".to_owned(),
            ))?
            .to_string();
        let display_name = match c.account().get_display_name().await {
            Ok(Some(name)) => name,
            _ => user_id.clone(),
        };

        Ok(UserValue {
            user_id,
            display_name,
            _client: client,
        })
    }
}

impl Object for UserValue {
    fn get_value(self: &Arc<Self>, field: &Value) -> Option<Value> {
        match field.as_str() {
            Some("user_id") => Some(Value::from(self.user_id.clone())),
            Some("display_name") => Some(Value::from(self.display_name.clone())),
            _ => None,
        }
    }

    fn enumerate(self: &Arc<Self>) -> Enumerator {
        Enumerator::Str(&["user_id", "display_name"])
    }
}

/// Reference
#[derive(Debug)]
pub struct ObjRef {
    id: String,
    obj_type: String,
}

impl ObjRef {
    pub(crate) fn new(id: String, obj_type: String) -> Self {
        ObjRef { id, obj_type }
    }
}

impl Object for ObjRef {
    fn get_value(self: &Arc<Self>, field: &Value) -> Option<Value> {
        match field.as_str() {
            Some("id") => Some(Value::from(self.id.clone())),
            Some("type") => Some(Value::from(self.obj_type.clone())),
            _ => None,
        }
    }

    fn enumerate(self: &Arc<Self>) -> Enumerator {
        Enumerator::Str(&["id", "type"])
    }
}

/// Hold a UtcDateTime for templates
#[derive(Debug)]
pub struct UtcDateTimeValue {
    date: UtcDateTime,
}

impl UtcDateTimeValue {
    pub(crate) fn new(date: UtcDateTime) -> Self {
        UtcDateTimeValue { date }
    }
}

impl Object for UtcDateTimeValue {
    fn get_value(self: &Arc<Self>, field: &Value) -> Option<Value> {
        match field.as_str() {
            Some("as_timestamp") => Some(Value::from(self.date.timestamp())),
            Some("as_rfc3339") => Some(Value::from(self.date.to_rfc3339())),
            _ => None,
        }
    }

    fn enumerate(self: &Arc<Self>) -> Enumerator {
        Enumerator::Str(&["as_timestamp"])
    }
}
