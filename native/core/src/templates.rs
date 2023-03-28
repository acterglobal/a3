use crate::{
    client::CoreClient,
    events::{
        calendar::CalendarEventEventContent,
        news::NewsEntryEventContent,
        pins::PinEventContent,
        tasks::{TaskEventContent, TaskListEventContent},
    },
    spaces::CreateSpaceSettings,
};

use async_stream::try_stream;
use core::pin::Pin;
use futures::{
    task::{Context as FuturesContext, Poll},
    Stream,
};
use indexmap::IndexMap;
use matrix_sdk::ruma::RoomId;
pub use minijinja::value::Value;
use minijinja::Environment;
use serde::Deserialize;
use std::{collections::BTreeMap, sync::Arc};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};
use toml::{Table, Value as TomlValue};

pub mod filters;
pub mod functions;
pub mod values;

use values::{ObjRef, UserValue};

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

    #[error("Referenced {0} '{1}' on {2} not found.")]
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
            | Input::Space { required, .. } => *required,
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
        #[serde(default, rename = "is-default")]
        is_default: bool,
        #[serde(flatten)]
        fields: CreateSpaceSettings,
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
    CalendarEvent {
        #[serde(flatten)]
        fields: CalendarEventEventContent,
    },
    NewsEntry {
        #[serde(flatten)]
        fields: NewsEntryEventContent,
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
    #[serde(rename = "0.1.1", alias = "0.1.0", alias = "0.1")]
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

pub struct Engine {
    root: TemplateV01,
    context: Context,
    users: BTreeMap<String, Arc<CoreClient>>,
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
                Value::from_struct_object(ObjRef::new(id, obj_type)),
            )
            .is_some()
        {
            Err(Error::ContextClash(name))
        } else {
            Ok(())
        }
    }

    pub async fn add_user(&mut self, name: String, client: CoreClient) -> Result<(), Error> {
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

        let env = {
            let mut env = Environment::new();

            // functions
            env.add_function("future", functions::future);
            env.add_function("now", functions::now);

            // filters

            env
        };

        let users = self.users.clone();
        let mut context = self.context.clone();
        let objects = self.root.objects.clone();
        let total = objects.len();
        let (default_user, default_user_key, mut default_space) = {
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
            tracing::trace!(total = objects.len(), "starting execution");
            let mut count = 0;
            for (i, (k, v)) in objects.into_iter().enumerate() {
                tracing::trace!(?i, count, "executing");
                count += 1;
                let reformatted = execute_value_template(TomlValue::Table(v), &env, &context)
                    .map_err(|e| Error::RenderingObject(i.to_string(), e.to_string()))?;
                let TomlValue::Table(t) = reformatted else {
                    unreachable!("We always get back a table after sending in a table.");
                };
                let Object { room, user, obj } = Table::try_into::<Object>(t)?;

                let client = if user.is_none() || user == default_user_key  {
                    default_user.clone().ok_or_else(|| Error::NoDefaultSet("user".to_string(), i.to_string()))?
                } else { // must be the case
                    let Some(username) = user else {
                        unimplemented!("never reached");
                    };
                    users.get(&username).ok_or_else(|| Error::UnknownReference("user".to_string(), i.to_string(), username))?.clone()
                };

                if let ObjectInner::Space { is_default, fields } = obj {
                    if is_default && default_space.is_some() {
                        Err(Error::TooManyDefaults("Space".to_owned()))?;
                    }
                    let new_room_id = client
                        .create_acter_space(fields)
                        .await
                        .map_err(|e| Error::Remap(format!("Creating space '{i}' failed"), e.to_string()))?;
                    context.insert(i.to_string(), Value::from_struct_object(ObjRef::new(new_room_id.to_string() , "space".to_owned())));
                    if is_default {
                        default_space = Some(i.to_string());
                    }
                    let retry_strategy = FibonacciBackoff::from_millis(100)
                        .map(jitter)
                        .take(10);
                    let fetcher_client = client.client().clone();
                    Retry::spawn(retry_strategy, move || {
                        std::future::ready(if fetcher_client
                            .get_joined_room(&new_room_id)
                            .is_none() {
                                Err(Error::Remap(
                                    format!("created space '{i}' ({new_room_id}) could not be found"),
                                        "Do you have a sync running?".to_owned()
                                    )
                                )
                            } else {
                                Ok(())
                            })
                    }).await?;

                    continue
                };

                let room_name = match room {
                    Some(r) => r,
                    None => default_space.clone().ok_or_else(|| Error::NoDefaultSet("room".to_string(), i.to_string()))?
                };

                let room_id_str = context
                    .get(&room_name)
                    .ok_or_else(|| Error::UnknownReference("room".to_string(),  room_name.clone(), i.to_string()))?
                    .get_attr("id")
                    .map_err(|e| Error::Remap(format!("{i} room={room_name} attr=id"), e.to_string()))?
                    .to_string();

                let room_id = RoomId::parse(room_id_str.clone())
                    .map_err(|e| Error::Remap(format!("{i}.room({room_name}).id({room_id_str}) parse failed"), e.to_string()))?;

                let room = client.client().get_joined_room(&room_id)
                        .ok_or_else(|| Error::UnknownReference(format!("{i}.room"),  room_name.clone(), i.to_string()))?;

                match obj {
                    ObjectInner::TaskList{ fields } => {
                        tracing::trace!(?fields, "submitting task list");
                        let id = room
                            .send(fields, None)
                            .await
                            .map_err(|e| Error::Remap(format!("{i} submission failed"), e.to_string()))?
                            .event_id;
                        context.insert(i.to_string(),
                            Value::from_struct_object(ObjRef::new(id.to_string(), "task-list".to_owned())));
                        yield
                    }
                    ObjectInner::Task{ fields } => {
                        tracing::trace!(?fields, "submitting task");
                        let id = room
                            .send(fields, None)
                            .await
                            .map_err(|e| Error::Remap(format!("{i} submission failed"), e.to_string()))?
                            .event_id;
                        context.insert(i.to_string(),
                            Value::from_struct_object(ObjRef::new(id.to_string(), "task".to_owned())));
                        yield
                    }
                    ObjectInner::CalendarEvent{ fields } => {
                        tracing::trace!(?fields, "submitting calendar event");
                        let id = room
                            .send(fields, None)
                            .await
                            .map_err(|e| Error::Remap(format!("{i} submission failed"), e.to_string()))?
                            .event_id;
                        context.insert(i.to_string(),
                            Value::from_struct_object(ObjRef::new(id.to_string(), "calendar-event".to_owned())));
                        yield
                    }
                    ObjectInner::Pin{ fields } => {
                        tracing::trace!(?fields, "submitting pin");
                        let id = room
                            .send(fields, None)
                            .await
                            .map_err(|e| Error::Remap(format!("{i} submission failed"), e.to_string()))?
                            .event_id;
                        context.insert(i.to_string(),
                            Value::from_struct_object(ObjRef::new(id.to_string(), "pin".to_owned())));
                        yield
                    }
                    ObjectInner::NewsEntry{ fields } => {
                        tracing::trace!(?fields, "submitting news entry");
                        let id = room
                            .send(fields, None)
                            .await
                            .map_err(|e| Error::Remap(format!("{i} submission failed"), e.to_string()))?
                            .event_id;
                        context.insert(i.to_string(),
                            Value::from_struct_object(ObjRef::new(id.to_string(), "news-entry".to_owned())));
                        yield
                    }
                    ObjectInner::Space { .. } => {
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

impl CoreClient {
    pub async fn template_engine(&self, template: &str) -> Result<Engine, Error> {
        let mut engine = Engine::with_template(template)?;
        engine.add_user("main".to_string(), self.clone()).await?;
        Ok(engine)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parsing_v1() -> anyhow::Result<()> {
        let tmpl = r#"
version = "0.1.1"
name = "Example Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }
space = { type = "space", required = true, description = "The acter space" }

[objects]
start_list = { type = "task-list", name = "{{ user.display_name() }}'s Acter onboarding list" }

[objects.task_1]
type = "task"
title = "Scroll through the news"
assignees = ["{{ user.user_id }}"]
task_list_id = "{{ start_list.id }}"
utc_due = "{{ now() | add_timedelta(mins=5) }}"

[objects.acter-website-pin]
type = "pin"
title = "Acter Website"
url = "https://acter.global"

[objects.acter-source-pin]
type = "pin"
title = "Acter Source Code"
url = "https://github.com/acterglobal/a3"

[objects.example-news]
type = "news-entry"
slides = [
{ body = "This is the news section", info = { size = 3264047, mimetype = "image/jpeg", thumbnail_info = { w = 400, h = 600, mimetype = "image/jpeg", size = 130511   }, w = 3840, h = 5760, "xyz.amorgan.blurhash" = "TQF=,g?uIo},={X5$c#+V@t2sRjF", thumbnail_url = "mxc://acter.global/aJhqfXrJRWXsFgWFRNlBlpnD" }, msgtype = "m.image", url = "mxc://acter.global/tVLtaQaErMyoXmcCroPZdfNG" }
]
       "#;

        let _engine = Engine::with_template(tmpl)?;

        Ok(())
    }
}
