
use serde::{Serialize, Deserialize, de::{DeserializeOwned, Deserializer}}; // 1.0.136
use anyhow::{Result, Context, bail}; // 1.0.53

use std::collections::btree_map::{BTreeMap, Entry};
use std::fmt::Debug;
use ruma::{
    UserId, events::reaction::ReactionEvent
};
use super::{Transition, Action};

#[derive(Serialize, Deserialize, Debug, Default, Clone)]
pub struct ReactionState(pub BTreeMap<String, Vec<Box<UserId>>>);

impl core::ops::Deref for ReactionState {
    type Target = BTreeMap<String, Vec<Box<UserId>>>;
    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl ReactionState {
    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
    }
}

impl Action for ReactionEvent {}

impl Transition for ReactionState {
    type Action = ReactionEvent;
    fn transition(&mut self, action: Self::Action) -> Result<bool> {
        match self.0.entry(action.content.relates_to.key) {
            Entry::Vacant(o) => {
                o.insert(vec![action.sender]);
                Ok(true)
            }
            Entry::Occupied(mut o) => {
                let users = o.get_mut();
                if !users.contains(&action.sender) {
                    // we ignore if the user is already in the list
                    users.push(action.sender);
                    Ok(true)
                } else  {
                    Ok(false)
                }
            }
        }
    }
}