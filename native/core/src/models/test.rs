use derive_builder::Builder;
use matrix_sdk_base::ruma::{
    user_id, EventId, MilliSecondsSinceUnixEpoch, OwnedEventId, OwnedRoomId, UserId,
};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use super::{default_model_execute, ActerModel, AnyActerModel, Capability, EventMeta};
use crate::{
    referencing::{ExecuteReference, IndexKey},
    store::Store,
    Result,
};

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize, Builder)]
#[builder(build_fn(name = "derive_builder_build"))]
pub struct TestModel {
    room_id: OwnedRoomId,
    event_id: OwnedEventId,
    event_meta: EventMeta,

    #[builder(default)]
    #[serde(skip, default)]
    indizes: Vec<IndexKey>,

    #[builder(default)]
    belongs_to: Vec<OwnedEventId>,

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
        if self.event_meta.is_none() {
            let event_id = self.event_id.clone().unwrap_or_else(|| {
                let ev = Uuid::new_v4().hyphenated().to_string();
                OwnedEventId::try_from(format!("${ev}")).unwrap()
            });
            let room_id = self.room_id.clone().unwrap_or_else(|| {
                let room_id = Uuid::new_v4().hyphenated().to_string();
                OwnedRoomId::try_from(format!("!{room_id}:example.org")).unwrap()
            });
            self.event_meta = Some(EventMeta {
                event_id,
                sender: user_id!("@test:example.org").to_owned(),
                origin_server_ts: MilliSecondsSinceUnixEpoch(123567890u32.into()),
                room_id,
                redacted: None,
            });
        }
        self.derive_builder_build()
    }
}

impl ActerModel for TestModel {
    fn event_meta(&self) -> &EventMeta {
        &self.event_meta
    }

    fn capabilities(&self) -> &[Capability] {
        &[Capability::Commentable, Capability::Reactable]
    }

    fn indizes(&self, _user_id: &UserId) -> Vec<IndexKey> {
        self.indizes.clone()
    }

    fn belongs_to(&self) -> Option<Vec<OwnedEventId>> {
        Some(self.belongs_to.clone())
    }

    fn transition(&mut self, _model: &AnyActerModel) -> Result<bool> {
        Ok(true)
    }

    async fn execute(self, store: &Store) -> Result<Vec<ExecuteReference>> {
        default_model_execute(store, self.into()).await
    }
}
