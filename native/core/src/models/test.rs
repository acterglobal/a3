use derive_builder::Builder;
use ruma::{OwnedRoomId, RoomId};
use ruma_common::{user_id, EventId, MilliSecondsSinceUnixEpoch, OwnedEventId, UserId};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use super::{default_model_execute, ActerModel, AnyActerModel, Capability, EventMeta};
use crate::{store::Store, Result};

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize, Builder)]
#[builder(build_fn(name = "derive_builder_build"))]
pub struct TestModel {
    room_id: OwnedRoomId,
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
        self.event_id(EventId::parse("$asdefttg").unwrap())
    }

    pub fn fake_meta() -> EventMeta {
        let ev = Uuid::new_v4().hyphenated().to_string();
        let room_id = Uuid::new_v4().hyphenated().to_string();

        EventMeta {
            event_id: OwnedEventId::try_from(format!("${ev}")).unwrap(),
            sender: user_id!("@test:example.org").to_owned(),
            origin_server_ts: MilliSecondsSinceUnixEpoch(123567890u32.into()),
            room_id: OwnedRoomId::try_from(format!("!{room_id}:example.org")).unwrap(),
            redacted: None,
        }
    }

    pub fn build(&mut self) -> std::result::Result<TestModel, TestModelBuilderError> {
        if self.room_id.is_none() {
            let room_id = Uuid::new_v4().hyphenated().to_string();
            self.room_id = OwnedRoomId::try_from(format!("!{room_id}:example.org")).ok();
        }
        self.derive_builder_build()
    }
}

impl ActerModel for TestModel {
    fn event_id(&self) -> &EventId {
        &self.event_id
    }
    fn room_id(&self) -> &RoomId {
        &self.room_id
    }

    fn capabilities(&self) -> &[Capability] {
        &[Capability::Commentable, Capability::Reactable]
    }

    fn indizes(&self, _user_id: &UserId) -> Vec<String> {
        self.indizes.clone()
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(self.belongs_to.clone())
    }

    fn transition(&mut self, _model: &AnyActerModel) -> Result<bool> {
        Ok(true)
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        default_model_execute(store, self.into()).await
    }
}
