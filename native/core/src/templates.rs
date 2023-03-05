use crate::events::pins::PinEventContent;
use crate::events::tasks::{TaskEventContent, TaskListEventContent};

use async_stream::try_stream;
use core::pin::Pin;
use futures::{
    task::{Context as FuturesContext, Poll},
    Stream,
};
use indexmap::IndexMap;
use matrix_sdk::ruma::{OwnedUserId, RoomId};
use matrix_sdk::Client as MatrixClient;
pub use minijinja::value::Value;
use minijinja::Environment;
use serde;
use serde::Deserialize;
use std::{collections::BTreeMap, sync::Arc};
use toml::{Table, Value as TomlValue};

#[derive(thiserror::Error, Debug)]
pub enum Error {
    #[error("Toml couldn't be parsed: {0:?}")]
    TomlDeserializationFailed(#[from] toml::de::Error),

    #[error("Missing inputs: {0:?} are required")]
    MissingInputs(Vec<String>),

    #[error("Missing fields: {1:?} are required on {0}")]
    MissingFields(String, Vec<String>),

    #[error("Error rendering template: {0}")]
    TomlSerializationError(#[from] toml::ser::Error),

    #[error("Error rendering template: {0}")]
    Rendering(#[from] minijinja::Error),

    #[error("Error rendering {0}: {1}")]
    RenderingObject(String, String),

    #[error("{0}: {1}")]
    Remap(String, String),

    #[error("Too Many defaults. Only one item per type can be set as default. But found more than one for '{0}'")]
    TooManyDefaults(String),

    #[error("Reference to {0} '{1}' on {2} not found.")]
    UnknownReference(String, String, String),

    #[error("{1} doesn't have '{0}' set but no default has been defined.")]
    NoDefaultSet(String, String),

    #[error("{0} already found in context.")]
    ContextClash(String),
}

#[derive(Deserialize)]
#[serde(tag = "type", rename_all = "kebab-case")]
pub enum Input {
    Text {
        #[serde(default)]
        required: bool,
        description: Option<String>,
    },
    User {
        #[serde(default)]
        required: bool,
        #[serde(default, rename = "is-default")]
        is_default: bool,
        description: Option<String>,
    },
    Space {
        #[serde(default)]
        required: bool,
        #[serde(default, rename = "is-default")]
        is_default: bool,
        description: Option<String>,
    },
}

impl Input {
    pub fn is_required(&self) -> bool {
        match self {
            Input::Text { required, .. }
            | Input::User { required, .. }
            | Input::Space { required, .. } => !!required,
            // _ => false,
        }
    }

    pub fn is_default(&self) -> bool {
        match self {
            Input::User { is_default, .. } | Input::Space { is_default, .. } => *is_default,
            _ => false,
        }
    }

    pub fn is_user(&self) -> bool {
        matches!(self, Input::User { .. })
    }

    pub fn is_space(&self) -> bool {
        matches!(self, Input::Space { .. })
    }
}

#[derive(Deserialize)]
#[serde(tag = "type", rename_all = "kebab-case")]
pub enum ObjectInner {
    Space {
        name: String,
    },
    TaskList {
        #[serde(flatten)]
        fields: TaskListEventContent,
    },
    Task {
        #[serde(flatten)]
        fields: TaskEventContent,
    },
    Pin {
        #[serde(flatten)]
        fields: PinEventContent,
    },
}

#[derive(Deserialize)]
pub struct Object {
    #[serde(alias = "in")]
    room: Option<String>,
    #[serde(alias = "as")]
    user: Option<String>,
    #[serde(flatten)]
    obj: ObjectInner,
}

#[derive(Deserialize)]
pub struct TemplateV01 {
    name: Option<String>,
    inputs: IndexMap<String, Input>,
    objects: IndexMap<String, toml::Table>,
}

#[derive(Deserialize)]
#[serde(tag = "version")]
pub enum TemplatesRoot {
    #[serde(rename = "0.1")]
    V01(TemplateV01),
}

type Context = BTreeMap<String, Value>;

pub struct ExecutionStream {
    total: u32,
    done: u32,
    stream: Pin<Box<dyn Stream<Item = Result<(), Error>> + Unpin>>,
}

fn execute_value_template(
    value: TomlValue,
    env: &Environment,
    context: &Context,
) -> Result<TomlValue, Error> {
    match value {
        TomlValue::String(s) => {
            let resp = env.render_str(&s, context)?;
            Ok(TomlValue::try_from(resp)?)
        }
        TomlValue::Array(v) => Ok(TomlValue::Array(
            v.into_iter()
                .map(|v| execute_value_template(v, env, context))
                .collect::<Result<Vec<TomlValue>, Error>>()?,
        )),
        TomlValue::Table(t) => {
            let mut new_table = toml::map::Map::with_capacity(t.len());
            for (key, value) in t.into_iter() {
                new_table.insert(
                    key.clone(),
                    execute_value_template(value, env, context)
                        .map_err(|e| Error::Remap(key, e.to_string()))?,
                );
            }
            Ok(TomlValue::Table(new_table))
        }
        _ => Ok(value),
    }
}

impl ExecutionStream {
    pub fn new(total: u32, stream: Box<dyn Stream<Item = Result<(), Error>> + Unpin>) -> Self {
        ExecutionStream {
            done: 0,
            total,
            stream: Pin::new(stream),
        }
    }

    pub fn total(&self) -> u32 {
        self.total
    }

    pub fn done_count(&self) -> u32 {
        self.done
    }
}

impl Stream for ExecutionStream {
    type Item = Result<(), Error>;

    fn poll_next(
        mut self: Pin<&mut Self>,
        cx: &mut FuturesContext<'_>,
    ) -> Poll<Option<Self::Item>> {
        let polled = self.stream.as_mut().poll_next(cx);
        match &polled {
            Poll::Ready(t) if t.is_some() => self.done += 1,
            _ => {}
        }
        polled
    }
}

#[derive(Debug)]
struct UserValue {
    user_id: String,
    display_name: String,
    client: Arc<MatrixClient>,
}

impl UserValue {
    async fn new(client: Arc<MatrixClient>) -> Result<Self, Error> {
        let user_id = client.user_id().unwrap().to_string();
        let display_name = match client.account().get_display_name().await {
            Ok(Some(name)) => name,
            _ => user_id.clone(),
        };

        Ok(UserValue {
            user_id,
            display_name,
            client,
        })
    }
}

impl minijinja::value::StructObject for UserValue {
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

#[derive(Debug)]
struct ObjRef {
    id: String,
    obj_type: String,
}

impl minijinja::value::StructObject for ObjRef {
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

pub struct Engine {
    root: TemplateV01,
    context: Context,
    users: BTreeMap<String, Arc<MatrixClient>>,
}

impl Engine {
    pub fn with_template(source: &str) -> Result<Self, Error> {
        let TemplatesRoot::V01(root) = toml::from_str::<TemplatesRoot>(source)?;

        Ok(Self {
            root,
            context: Default::default(),
            users: Default::default(),
        })
    }

    pub fn requested_inputs(&self) -> &IndexMap<String, Input> {
        &self.root.inputs
    }

    pub fn add_context(&mut self, name: String, value: Value) -> Result<(), Error> {
        if self.context.insert(name.clone(), value).is_some() {
            Err(Error::ContextClash(name))
        } else {
            Ok(())
        }
    }

    pub fn add_ref(&mut self, name: String, obj_type: String, id: String) -> Result<(), Error> {
        if self
            .context
            .insert(
                name.clone(),
                Value::from_struct_object(ObjRef { id, obj_type }),
            )
            .is_some()
        {
            Err(Error::ContextClash(name))
        } else {
            Ok(())
        }
    }

    pub async fn add_user(&mut self, name: String, client: MatrixClient) -> Result<(), Error> {
        let cl = Arc::new(client);
        let user_value = UserValue::new(cl.clone()).await?;
        self.users.insert(name.clone(), cl.clone());
        if self
            .context
            .insert(name.clone(), Value::from_struct_object(user_value))
            .is_some()
        {
            Err(Error::ContextClash(name))
        } else {
            Ok(())
        }
    }

    pub fn execute(&self) -> Result<ExecutionStream, Error> {
        tracing::trace!(name = ?self.root.name, "executing");

        let env = Environment::new();
        let users = self.users.clone();
        let mut context = self.context.clone();
        let objects = self.root.objects.clone();
        let total = objects.len();
        let (default_user, default_user_key, default_space) = {
            let mut default_user = None;
            let mut default_user_name = None;
            let mut default_space = None;

            for (name, input) in self.requested_inputs() {
                tracing::trace!(
                    name,
                    is_default = input.is_default(),
                    is_user = input.is_user(),
                    "parsing input",
                );
                if input.is_required() && !context.contains_key(name) {
                    return Err(Error::MissingInputs(vec![name.to_string()]));
                }
                if input.is_default() {
                    if input.is_user() {
                        if default_user.is_some() {
                            return Err(Error::TooManyDefaults("User".to_owned()));
                        }
                        default_user_name = Some(name.clone());
                        default_user = Some(
                            users
                                .get(name)
                                .ok_or(Error::MissingInputs(vec![name.to_string()]))?
                                .clone(),
                        );
                    }

                    if input.is_space() {
                        if default_space.is_some() {
                            return Err(Error::TooManyDefaults("Space".to_owned()));
                        }
                        default_space = Some(name.clone());
                    }
                }
            }
            (default_user, default_user_name, default_space)
        };

        tracing::trace!(?default_user_key, "starting stream");

        let stream = try_stream! {
            for (key, fields) in objects.into_iter() {
                let reformatted = execute_value_template(TomlValue::Table(fields), &env, &context)
                    .map_err(|e| Error::RenderingObject(key.clone(), e.to_string()))?;
                let TomlValue::Table(t) = reformatted else {
                    unreachable!("We always get back a table after sending in a table.");
                };
                let Object { room, user, obj } = Table::try_into::<Object>(t)?;

                let client = if user.is_none() || user == default_user_key  {
                    default_user.clone().ok_or_else(|| Error::NoDefaultSet("user".to_string(), key.clone()))?
                } else { // must be the case
                    let Some(username) = user else {
                        unimplemented!("never reached");
                    };
                    users.get(&username).ok_or_else(|| Error::UnknownReference("user".to_string(), key.clone(), username))?.clone()
                };

                if let ObjectInner::Space { name } = obj {
                    unimplemented!("Creating spaces not yet implemented");
                };


                let room_name = match room {
                    Some(r) => r,
                    None => default_space.clone().ok_or_else(|| Error::NoDefaultSet("room".to_string(), key.clone()))?
                };

                let room_id_str = context
                    .get(&room_name)
                    .ok_or_else(|| Error::UnknownReference("room".to_string(), key.clone(), room_name.clone()))?
                    .get_attr("id")
                    .map_err(|e| Error::Remap(format!("{key} room={room_name} attr=id"), e.to_string()))?
                    .to_string();

                let room_id = RoomId::parse(room_id_str.clone())
                    .map_err(|e| Error::Remap(format!("{key}.room({room_name}).id({room_id_str}) parse failed"), e.to_string()))?;

                let room = client.get_joined_room(&room_id)
                        .ok_or_else(|| Error::UnknownReference("user.room".to_string(), key.clone(), room_name.clone()))?;

                match obj {
                    ObjectInner::TaskList{ fields } => {
                        let id = room.send(fields, None).await.map_err(|e| Error::Remap(format!("{key} submission failed"), e.to_string()))?.event_id;
                        context.insert(key, Value::from_struct_object(ObjRef { id: id.to_string() , obj_type: "task-list".to_owned()}));
                        yield

                    }
                    ObjectInner::Task{ fields } => {
                        let id = room.send(fields, None).await.map_err(|e| Error::Remap(format!("{key} submission failed"), e.to_string()))?.event_id;
                        context.insert(key, Value::from_struct_object(ObjRef { id: id.to_string() , obj_type: "task".to_owned()}));
                        yield

                    }
                    ObjectInner::Pin{ fields } => {
                        let id = room.send(fields, None).await.map_err(|e| Error::Remap(format!("{key} submission failed"), e.to_string()))?.event_id;
                        context.insert(key, Value::from_struct_object(ObjRef { id: id.to_string() , obj_type: "pin".to_owned()}));
                        yield

                    }
                    ObjectInner::Space { name } => {
                        unreachable!("we already handled that above");
                    }

                }
            }

        };

        Ok(ExecutionStream::new(
            total as u32,
            Box::new(Box::pin(stream)),
        ))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parsing_v1() -> anyhow::Result<()> {
        let tmpl = r#"
version = "0.1"
name = "Example Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }
space = { type = "space", required = true, description = "The effektio space" }

[objects]
start_list = { type = "task-list", name = "{{ inputs.user.display_name() }}'s Acter onboarding list" }

[objects.task_1]
type = "task"
title = "Scroll through the news"
assignees = ["{{ inputs.user.user_id }}"]
task_list_id = "{{ objects.start_list.id }}"
utc_due = "{{ now() | add_timedelta(mins=5) }}"

[objects.acter-website-pin]
type = "pin"
title = "Acter Website"
url = "https://acter.global"

[objects.acter-source-pin]
type = "pin"
title = "Acter Source Code"
url = "https://github.com/acterglobal/a3"

        "#;

        let _engine = Engine::with_template(tmpl)?;

        Ok(())
    }
}
