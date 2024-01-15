use ruma_common::{EventId, UserId};
use ruma_events::room::redaction::{OriginalRoomRedactionEvent, RoomRedactionEventContent};
use serde::{Deserialize, Serialize};
use std::ops::Deref;
use tracing::{info, trace};

use super::{ActerModel, EventMeta};
use crate::{store::Store, Result};

static REDACTIONS_FIELD: &str = "redactions";

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Redaction {
    pub(crate) inner: RoomRedactionEventContent,
    pub meta: EventMeta,
}

impl Deref for Redaction {
    type Target = RoomRedactionEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl Redaction {
    pub fn index_for<T: AsRef<str>>(parent: &T) -> String {
        let r = parent.as_ref();
        format!("{r}::{REDACTIONS_FIELD}")
    }
}

impl ActerModel for Redaction {
    fn indizes(&self, _user_id: &UserId) -> Vec<String> {
        self.belongs_to()
            .expect("we always have some as entries")
            .into_iter()
            .map(|v| Redaction::index_for(&v))
            .collect()
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        let belongs_to = self.belongs_to().unwrap();
        trace!(event_id=?self.event_id(), ?belongs_to, "applying redaction");
        info!("applying redaction ------------------------------------------------");
        Ok(vec![])
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        self.inner.redacts.as_ref().map(|x| vec![x.to_string()])
    }
}

impl From<OriginalRoomRedactionEvent> for Redaction {
    fn from(outer: OriginalRoomRedactionEvent) -> Self {
        let OriginalRoomRedactionEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        Redaction {
            inner: content,
            meta: EventMeta {
                room_id,
                event_id,
                sender,
                origin_server_ts,
            },
        }
    }
}
