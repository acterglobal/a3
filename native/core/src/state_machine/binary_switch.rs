
use serde::{Serialize, Deserialize, de::{DeserializeOwned, Deserializer}}; // 1.0.136
use anyhow::{Result, Context, bail}; // 1.0.53

use std::collections::btree_map::{BTreeMap, Entry};
use std::fmt::Debug;

use super::Transition;

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct BinarySwitch(BinarySwitchState);

impl BinarySwitch {
    pub fn new() -> Self {
        BinarySwitch(BinarySwitchState::Off)
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub enum BinarySwitchState {
    On,
    Off,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub enum BinarySwitchAction {
    SwitchOn,
    SwitchOff
}

impl Transition for BinarySwitch {
    type Action = BinarySwitchAction;
    fn transition(&mut self, action: Self::Action) -> Result<()> {
        self.0 = match action {
            BinarySwitchAction::SwitchOn => BinarySwitchState::On,
            BinarySwitchAction::SwitchOff => BinarySwitchState::Off,
        };
        Ok(())
    }
}