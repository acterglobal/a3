use serde::{Serialize, Deserialize, de::{DeserializeOwned, Deserializer}}; // 1.0.136
use anyhow::{Result, Context, bail}; // 1.0.53

use std::collections::btree_map::{BTreeMap, Entry};
use std::fmt::Debug;

mod traits;
mod binary_switch;

pub use traits::Transition;
pub use binary_switch::{BinarySwitch, BinarySwitchAction};

#[derive(Serialize, Deserialize, Debug, Clone)]
struct Redacted {
    by: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    reason: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct ReactionAction {
    key: String,
    user: String,
}

#[derive(Serialize, Deserialize, Debug, Default, Clone)]
struct ReactionState(BTreeMap<String, Vec<String>>);

impl core::ops::Deref for ReactionState {
    type Target = BTreeMap<String, Vec<String>>;
    fn deref(&self) -> &Self::Target {
        &self.0
    }
}


impl ReactionState {
    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
    }
}

impl Transition for ReactionState {
    type Action = ReactionAction;
    fn transition(&mut self, action: Self::Action) -> Result<()> {
        match self.0.entry(action.key) {
            Entry::Vacant(o) => {
                o.insert(vec![action.user]);
            }
            Entry::Occupied(mut o) => {
                let users = o.get_mut();
                if !users.contains(&action.user) {
                    // we ignore if the user is already in the list
                    users.push(action.user);
                };
            }
        };
    Ok(())
    }
}

fn deserialize_optional_field<'de, T, D>(deserializer: D) -> Result<Option<T>, D::Error>
where
    D: Deserializer<'de>,
    T: Deserialize<'de>,
{
    Ok(Option::deserialize(deserializer)?)
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct StatefulObject<T>
where T: Transition
{
    #[serde(deserialize_with = "deserialize_optional_field")]
    #[serde(skip_serializing_if = "Option::is_none")]
    state: Option<T>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    redacted: Option<Redacted>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    archived: Option<String>,

    #[serde(default)]
    #[serde(skip_serializing_if = "ReactionState::is_empty")]
    reactions: ReactionState,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    history: Vec<GenericAction<T::Action>>,
}

impl<T:Transition> StatefulObject<T> {
    pub fn new(state: T) -> Self {
        StatefulObject {
            state: Some(state),
            redacted: None,
            archived: None,
            reactions: ReactionState(Default::default()),
            history: Vec::new(),
        }
    }
}

#[derive(Serialize, Deserialize, Clone, Debug)]
enum GenericAction<A: Clone + Debug> {
    Redaction(Redacted),
    Archive(String),
    Reaction(ReactionAction),
    ObjectAction(A),
}

impl<T> Transition for StatefulObject<T>
where T: Transition + Serialize + DeserializeOwned
{
    type Action = GenericAction<<T as Transition>::Action>;
    fn transition(&mut self, action: Self::Action) -> Result<()> {
        if self.redacted.is_some() {
            bail!("Object has been redacted already");
        }
        let history_record = action.clone(); 
        match action {
            GenericAction::Archive(u) => self.archived = Some(u),
            GenericAction::Redaction(r) => {
                self.redacted = Some(r);
                self.state = None;
            }
            GenericAction::Reaction(r) => self.reactions.transition(r)?,
            GenericAction::ObjectAction(a) => {
                let mut state = self.state.take().context("Invalid state")?;
                state.transition(a)?;
                self.state = Some(state);
            }
        };
        self.history.push(history_record);
        Ok(())
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use serde_json;
    #[test]
    fn smoketest() -> Result<()> {
        let mut m = StatefulObject::new(BinarySwitch::new());

        m.transition(GenericAction::ObjectAction(BinarySwitchAction::SwitchOn))?;
        let on_json = serde_json::to_string(&m)?;
        println!("After on: {:}", on_json);

        m.transition(GenericAction::ObjectAction(BinarySwitchAction::SwitchOff))?;
        let off_json = serde_json::to_string(&m)?;
        println!("After off: {:}", off_json);

        let mut recov = serde_json::from_str::<StatefulObject<BinarySwitch>>(&on_json)?;
        println!("Recovered State: {:?}", recov);

        recov.transition(GenericAction::ObjectAction(BinarySwitchAction::SwitchOff))?;
        println!("Recovered State off: {:?}", recov);

        recov.transition(GenericAction::Redaction(Redacted{by: "Ben".to_owned(), reason: None}))?;
        let redacetd = serde_json::to_string(&recov)?;
        println!("Redacted State: {:?}", redacetd);

        assert!(recov.transition(GenericAction::ObjectAction(BinarySwitchAction::SwitchOn)).is_err());
        Ok(())
    }
}