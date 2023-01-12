use derive_builder::Builder;
use matrix_sdk::ruma::{event_id, OwnedEventId};
use serde::{Deserialize, Serialize};

use crate::models::EffektioModel;

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize, Builder)]
pub struct TestModel {
    event_id: OwnedEventId,
    #[builder(default)]
    indizes: Vec<String>,
    #[builder(default)]
    belongs_to: Vec<String>,
    #[builder(default)]
    transition: bool,
}

impl TestModelBuilder {
    pub fn simple(&mut self) -> &mut Self {
        self.event_id(OwnedEventId::try_from("$asdefttg").unwrap())
    }
}

impl EffektioModel for TestModel {
    fn event_id(&self) -> &matrix_sdk::ruma::EventId {
        &self.event_id
    }
    fn indizes(&self) -> Vec<String> {
        self.indizes.clone()
    }
    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(self.belongs_to.clone())
    }

    fn transition(&mut self, _model: &super::AnyEffektioModel) -> crate::Result<bool> {
        Ok(true)
    }
}
