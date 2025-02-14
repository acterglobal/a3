mod any;
mod attachments;
mod calendar;
mod capabilities;
mod comments;
mod common;
mod conversion;
mod execution;
mod meta;
mod news;
mod pins;
mod reactions;
mod read_receipts;
mod redaction;
mod rsvp;
pub mod status;
mod stories;
mod tag;
mod tasks;
#[cfg(any(test, feature = "testing"))]
mod test;

pub use any::{ActerModel, AnyActerModel};
pub use attachments::{Attachment, AttachmentUpdate, AttachmentsManager, AttachmentsStats};
pub use calendar::{CalendarEvent, CalendarEventUpdate};
pub use capabilities::Capability;
pub use comments::{Comment, CommentUpdate, CommentsManager, CommentsStats};
pub use common::*;
pub use core::fmt::Debug;
pub(crate) use execution::default_model_execute;
pub use meta::{can_redact, EventMeta};
pub use news::{NewsEntry, NewsEntryUpdate};
pub use pins::{Pin, PinUpdate};
pub use reactions::{Reaction, ReactionManager, ReactionStats};
pub use read_receipts::{ReadReceipt, ReadReceiptStats, ReadReceiptsManager};
pub use redaction::RedactedActerModel;
pub use rsvp::{Rsvp, RsvpManager, RsvpStats};
pub use status::{ActerSupportedRoomStatusEvents, RoomStatus};
pub use stories::{Story, StoryUpdate};
pub use tag::Tag;
pub use tasks::{
    Task, TaskList, TaskListUpdate, TaskSelfAssign, TaskSelfUnassign, TaskStats, TaskUpdate,
};

#[cfg(any(test, feature = "testing"))]
pub use test::{TestModel, TestModelBuilder, TestModelBuilderError};

pub use crate::store::Store;

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{events::AnyActerEvent, models::conversion::ParseError, Result};

    use matrix_sdk_base::ruma::owned_event_id;
    #[test]
    fn ensure_minimal_tasklist_parses() -> Result<()> {
        let json_raw = r#"{"type":"global.acter.dev.tasklist",
            "room_id":"!euhIDqDVvVXulrhWgN:ds9.acter.global","sender":"@odo:ds9.acter.global",
            "content":{"name":"Daily Security Brief"},"origin_server_ts":1672407531453,
            "unsigned":{"age":11523850},
            "event_id":"$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c",
            "user_id":"@odo:ds9.acter.global","age":11523850}"#;
        let event = serde_json::from_str::<AnyActerEvent>(json_raw)?;
        AnyActerModel::try_from(event).unwrap();
        Ok(())
    }
    #[test]
    fn ensure_minimal_pin_parses() -> Result<()> {
        let json_raw = r#"{"type":"global.acter.dev.pin",
            "room_id":"!euhIDqDVvVXulrhWgN:ds9.acter.global","sender":"@odo:ds9.acter.global",
            "content":{"title":"Seat arrangement"},"origin_server_ts":1672407531453,
            "unsigned":{"age":11523850},
            "event_id":"$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c",
            "user_id":"@odo:ds9.acter.global","age":11523850}"#;
        let event = serde_json::from_str::<AnyActerEvent>(json_raw)?;
        AnyActerModel::try_from(event).unwrap();
        // assert!(matches!(event, AnyCreation::TaskList(_)));
        Ok(())
    }

    #[test]
    #[allow(unused_variables)]
    fn ensure_redacted_news_parses() -> Result<()> {
        let json_raw = r#"{
            "content": {},
            "origin_server_ts": 1689158713657,
            "room_id": "!uUufOaBOZwafrtxhoO:effektio.org",
            "sender": "@emilvincentz:effektio.org",
            "type": "global.acter.dev.news",
            "unsigned": {
              "redacted_by": "$2_k7NsG2GOGfyeNOvV55OovysVl7WGKgGEY2hv6VosY",
              "redacted_because": {
                "type": "m.room.redaction",
                "room_id": "!uUufOaBOZwafrtxhoO:effektio.org",
                "sender": "@ben:acter.global",
                "content": {
                  "reason": "",
                  "redacts": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco"
                },
                "redacts": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco",
                "origin_server_ts": 1694550003475,
                "unsigned": {
                  "age": 56316493,
                  "transaction_id": "1c85807d10074b17941f84ac02f168ee"
                },
                "event_id": "$2_k7NsG2GOGfyeNOvV55OovysVl7WGKgGEY2hv6VosY",
                "user_id": "@ben:acter.global",
                "age": 56316493
              }
            },
            "event_id": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco",
            "user_id": "@emilvincentz:effektio.org",
            "redacted_because": {
              "type": "m.room.redaction",
              "room_id": "!uUufOaBOZwafrtxhoO:effektio.org",
              "sender": "@ben:acter.global",
              "content": {
                "reason": "",
                "redacts": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco"
              },
              "redacts": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco",
              "origin_server_ts": 1694550003475,
              "unsigned": {
                "age": 56316493,
                "transaction_id": "1c85807d10074b17941f84ac02f168ee"
              },
              "event_id": "$2_k7NsG2GOGfyeNOvV55OovysVl7WGKgGEY2hv6VosY",
              "user_id": "@ben:acter.global",
              "age": 56316493
            }
          }"#;
        let event = serde_json::from_str::<AnyActerEvent>(json_raw)?;
        let acter_ev_result = AnyActerModel::try_from(event.clone());
        let model_type = "global.acter.dev.news".to_owned();
        let event_id = owned_event_id!("$2_k7NsG2GOGfyeNOvV55OovysVl7WGKgGEY2hv6VosY");
        assert!(
            matches!(
                acter_ev_result,
                Err(ParseError::ModelRedacted {
                    ref model_type,
                    meta: EventMeta { ref event_id, .. },
                    ..
                })
            ),
            "Didn’t receive expected error: {acter_ev_result:?}"
        );
        // assert!(matches!(event, AnyCreation::TaskList(_)));
        Ok(())
    }

    #[test]
    #[allow(unused_variables)]
    fn ensure_redacted_pin_parses() -> Result<()> {
        let json_raw = r#"{
            "content": {},
            "origin_server_ts": 1689158713657,
            "room_id": "!uUufOaBOZwafrtxhoO:effektio.org",
            "sender": "@emilvincentz:effektio.org",
            "type": "global.acter.dev.pin",
            "unsigned": {
              "redacted_by": "$2_k7NsG2GOGfyeNOvV55OovysVl7WGKgGEY2hv6VosY",
              "redacted_because": {
                "type": "m.room.redaction",
                "room_id": "!uUufOaBOZwafrtxhoO:effektio.org",
                "sender": "@ben:acter.global",
                "content": {
                  "reason": "",
                  "redacts": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco"
                },
                "redacts": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco",
                "origin_server_ts": 1694550003475,
                "unsigned": {
                  "age": 56316493,
                  "transaction_id": "1c85807d10074b17941f84ac02f168ee"
                },
                "event_id": "$2_k7NsG2GOGfyeNOvV55OovysVl7WGKgGEY2hv6VosY",
                "user_id": "@ben:acter.global",
                "age": 56316493
              }
            },
            "event_id": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco",
            "user_id": "@emilvincentz:effektio.org",
            "redacted_because": {
              "type": "m.room.redaction",
              "room_id": "!uUufOaBOZwafrtxhoO:effektio.org",
              "sender": "@ben:acter.global",
              "content": {
                "reason": "",
                "redacts": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco"
              },
              "redacts": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco",
              "origin_server_ts": 1694550003475,
              "unsigned": {
                "age": 56316493,
                "transaction_id": "1c85807d10074b17941f84ac02f168ee"
              },
              "event_id": "$2_k7NsG2GOGfyeNOvV55OovysVl7WGKgGEY2hv6VosY",
              "user_id": "@ben:acter.global",
              "age": 56316493
            }
          }"#;
        let event = serde_json::from_str::<AnyActerEvent>(json_raw)?;
        let acter_ev_result = AnyActerModel::try_from(event);
        let model_type = "global.acter.dev.pin".to_owned();
        let event_id = owned_event_id!("$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c");
        assert!(
            matches!(
                acter_ev_result,
                Err(ParseError::ModelRedacted {
                    ref model_type,
                    meta: EventMeta { ref event_id, .. },
                    ..
                })
            ),
            "Didn’t receive expected error: {acter_ev_result:?}"
        );
        // assert!(matches!(event, AnyCreation::TaskList(_)));
        Ok(())
    }
}
