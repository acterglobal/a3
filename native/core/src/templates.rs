use crate::events::pins::PinEventContent;
use crate::events::tasks::{TaskEventContent, TaskListEventContent};

use async_stream::try_stream;
use core::pin::Pin;
use futures::{
    task::{Context as FuturesContext, Poll},
    Stream,
};
use indexmap::IndexMap;
use matrix_sdk::Client as MatrixClient;
pub use minijinja::value::Value;
use minijinja::Environment;
use serde;
use serde::Deserialize;
use std::collections::BTreeMap;
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

    #[error("Too Many defaults. Only one item per type can be set as default. But found more than one for '{0}'")]
    TooManyDefaults(String),
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
        #[serde(default)]
        is_default: bool,
        description: Option<String>,
    },
    Space {
        #[serde(default)]
        required: bool,
        #[serde(default)]
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
pub enum Object {
    Space {
        name: String,
        #[serde(alias = "as")]
        user: Option<String>,
    },
    TaskList {
        #[serde(alias = "in")]
        room: Option<String>,
        #[serde(alias = "as")]
        user: Option<String>,
        #[serde(flatten)]
        fields: TaskListEventContent,
    },
    Task {
        #[serde(alias = "in")]
        room: Option<String>,
        #[serde(alias = "as")]
        user: Option<String>,
        #[serde(flatten)]
        fields: TaskEventContent,
    },
    Pin {
        #[serde(alias = "in")]
        room: Option<String>,
        #[serde(alias = "as")]
        user: Option<String>,
        #[serde(flatten)]
        fields: PinEventContent,
    },
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
            let resp = env.compile_expression(&s)?.eval(context)?;
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
                new_table.insert(key, execute_value_template(value, env, context)?);
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
    users: BTreeMap<String, MatrixClient>,
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

    pub fn add_context(&mut self, name: String, value: Value) {
        self.context.insert(name, value);
    }

    pub fn add_user(&mut self, name: String, client: MatrixClient) {
        self.users.insert(name, client);
    }

    pub fn execute(&self) -> Result<ExecutionStream, Error> {
        tracing::trace!(name = ?self.root.name, "executing");

        let env = Environment::new();
        let users = self.users.clone();
        let context = self.context.clone();
        let objects = self.root.objects.clone();
        let total = objects.len();
        let mut default_user = None;
        let mut default_space = None;

        for (name, input) in self.requested_inputs() {
            if input.is_required() && !context.contains_key(name) {
                return Err(Error::MissingInputs(vec![name.to_string()]));
            }
            if input.is_default() {
                if input.is_user() {
                    if default_user.is_some() {
                        return Err(Error::TooManyDefaults("User".to_owned()));
                    }
                    default_user = Some(
                        users
                            .get(name)
                            .ok_or(Error::MissingInputs(vec![name.to_string()]))?,
                    );
                }

                if input.is_space() {
                    if default_space.is_some() {
                        return Err(Error::TooManyDefaults("Space".to_owned()));
                    }
                    default_space = Some(name);
                }
            }
        }

        let stream = try_stream! {
            for (_name, fields) in objects.into_iter() {
                let reformatted = execute_value_template(TomlValue::Table(fields), &env, &context)?;
                let TomlValue::Table(t) = reformatted else {
                    unreachable!();
                };
                let _obj = Table::try_into::<Object>(t)?;
                yield
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
