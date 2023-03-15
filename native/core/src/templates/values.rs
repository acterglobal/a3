use minijinja::value::{StructObject, Value};
use std::sync::Arc;

use crate::{client::CoreClient, events::UtcDateTime};

use super::Error;

/// Hold a User client
#[derive(Debug)]
pub struct UserValue {
    user_id: String,
    display_name: String,
    _client: Arc<CoreClient>,
}

impl UserValue {
    pub(crate) async fn new(client: Arc<CoreClient>) -> Result<Self, Error> {
        let user_id = client
            .client()
            .user_id()
            .ok_or(Error::Remap(
                "user".to_string(),
                "missing user_id".to_string(),
            ))?
            .to_string();
        let display_name = match client.client().account().get_display_name().await {
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

impl StructObject for UserValue {
    fn get_field(&self, name: &str) -> Option<Value> {
        match name {
            "user_id" => Some(Value::from(self.user_id.clone())),
            "display_name" => Some(Value::from(self.display_name.clone())),
            _ => None,
        }
    }

    fn static_fields(&self) -> Option<&'static [&'static str]> {
        Some(&["user_id", "display_name"][..])
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

impl StructObject for ObjRef {
    fn get_field(&self, name: &str) -> Option<Value> {
        match name {
            "id" => Some(Value::from(self.id.clone())),
            "type" => Some(Value::from(self.obj_type.clone())),
            _ => None,
        }
    }

    fn static_fields(&self) -> Option<&'static [&'static str]> {
        Some(&["id", "type"][..])
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

impl StructObject for UtcDateTimeValue {
    fn get_field(&self, name: &str) -> Option<Value> {
        match name {
            "as_timestamp" => Some(Value::from(self.date.timestamp())),
            "as_rfc3339" => Some(Value::from(self.date.to_rfc3339())),
            _ => None,
        }
    }

    fn static_fields(&self) -> Option<&'static [&'static str]> {
        Some(&["as_timestamp"][..])
    }
}
