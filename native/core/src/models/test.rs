use derive_builder::Builder;
use matrix_sdk::ruma::{
    event_id, room_id, user_id, EventId, MilliSecondsSinceUnixEpoch, OwnedEventId,
};
use serde::{Deserialize, Serialize};

use super::EventMeta;
use crate::models::ActerModel;

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

    pub fn fake_meta() -> EventMeta {
        EventMeta {
            event_id: event_id!("$ASDas29ak").to_owned(),
            sender: user_id!("@test:example.org").to_owned(),
            origin_server_ts: MilliSecondsSinceUnixEpoch(123567890u32.into()),
            room_id: room_id!("!5678ijhgasdf093:Asdfa").to_owned(),
        }
    }
}

impl ActerModel for TestModel {
    fn event_id(&self) -> &EventId {
        &self.event_id
    }

    fn capabilities(&self) -> &[super::Capability] {
        &[super::Capability::Commentable]
    }

    fn indizes(&self) -> Vec<String> {
        self.indizes.clone()
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(self.belongs_to.clone())
    }

    fn transition(&mut self, _model: &super::AnyActerModel) -> crate::Result<bool> {
        Ok(true)
    }

    async fn execute(self, store: &super::Store) -> crate::Result<Vec<String>> {
        super::default_model_execute(store, self.into()).await
    }
}
