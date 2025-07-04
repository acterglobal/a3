use crate::config::MatrixCoreTypeConfig;
use acter_core::meta::EventMeta as CoreEventMeta;
use matrix_sdk::{
    ruma::{events::room::redaction::OriginalRoomRedactionEvent, UserId},
    Room,
};
pub type EventMeta = CoreEventMeta<MatrixCoreTypeConfig>;

pub fn event_meta_for_redacted_source(value: &OriginalRoomRedactionEvent) -> Option<EventMeta> {
    let target_event_id: matrix_sdk::ruma::OwnedEventId = value.redacts.clone()?;

    Some(EventMeta {
        event_id: target_event_id,
        sender: value.sender.clone(),
        room_id: value.room_id.clone(),
        timestamp: value.origin_server_ts,
        redacted: None,
    })
}

pub async fn can_redact(room: &Room, sender_id: &UserId) -> crate::error::Result<bool> {
    let client = room.client();
    let Some(user_id) = client.user_id() else {
        // not logged in means we can't redact
        return Ok(false);
    };
    Ok(if sender_id == user_id {
        room.can_user_redact_own(user_id).await?
    } else {
        room.can_user_redact_other(user_id).await?
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use matrix_sdk_base::ruma::{event_id, room_id, user_id, MilliSecondsSinceUnixEpoch, UInt};
    use serde_json::{json, Value};

    fn create_matrix_style_event_meta() -> EventMeta {
        EventMeta {
            event_id: event_id!("$143273582443PhrSn:example.org").to_owned(),
            sender: user_id!("@alice:example.org").to_owned(),
            timestamp: MilliSecondsSinceUnixEpoch(UInt::new(1432735824653u64).unwrap()),
            room_id: room_id!("!636q39766251:example.org").to_owned(),
            redacted: None,
        }
    }

    fn create_matrix_style_event_json() -> Value {
        json!({
            "event_id": "$143273582443PhrSn:example.org",
            "sender": "@alice:example.org",
            "origin_server_ts": 1432735824653u64,
            "room_id": "!636q39766251:example.org",
            "redacted": null
        })
    }

    #[test]
    fn test_event_meta_serialization_matrix_style() {
        let event_meta = create_matrix_style_event_meta();
        let serialized = serde_json::to_string(&event_meta).unwrap();

        // Verify the serialized format matches matrix.org style
        let expected = r#"{"event_id":"$143273582443PhrSn:example.org","sender":"@alice:example.org","timestamp":1432735824653,"room_id":"!636q39766251:example.org","redacted":null}"#;
        assert_eq!(serialized, expected);
    }

    #[test]
    fn test_event_meta_deserialization_matrix_style() {
        let json = create_matrix_style_event_json();
        let deserialized: EventMeta = serde_json::from_value(json).unwrap();

        let expected = create_matrix_style_event_meta();
        assert_eq!(deserialized, expected);
    }

    #[test]
    fn test_event_meta_roundtrip_matrix_style() {
        let original = create_matrix_style_event_meta();
        let serialized = serde_json::to_string(&original).unwrap();
        let deserialized: EventMeta = serde_json::from_str(&serialized).unwrap();

        assert_eq!(original, deserialized);
    }

    #[test]
    fn test_event_meta_with_redacted_event_matrix_style() {
        let event_meta = EventMeta {
            event_id: event_id!("$143273582443PhrSn:example.org").to_owned(),
            sender: user_id!("@alice:example.org").to_owned(),
            timestamp: MilliSecondsSinceUnixEpoch(UInt::new(1432735824653u64).unwrap()),
            room_id: room_id!("!636q39766251:example.org").to_owned(),
            redacted: Some(event_id!("$redacted_event:example.org").to_owned()),
        };

        let serialized = serde_json::to_string(&event_meta).unwrap();
        let deserialized: EventMeta = serde_json::from_str(&serialized).unwrap();

        assert_eq!(event_meta, deserialized);
        assert_eq!(
            deserialized.redacted,
            Some(event_id!("$redacted_event:example.org").to_owned())
        );
    }

    #[test]
    fn test_event_meta_timestamp_alias_matrix_style() {
        // Test that the "origin_server_ts" alias works for deserialization
        let json = json!({
            "event_id": "$143273582443PhrSn:example.org",
            "sender": "@alice:example.org",
            "origin_server_ts": 1432735824653u64,
            "room_id": "!636q39766251:example.org"
        });

        let deserialized: EventMeta = serde_json::from_value(json).unwrap();

        assert_eq!(
            deserialized.timestamp,
            MilliSecondsSinceUnixEpoch(UInt::new(1432735824653u64).unwrap())
        );
    }

    #[test]
    fn test_event_meta_missing_redacted_field_matrix_style() {
        // Test that missing redacted field defaults to None
        let json = json!({
            "event_id": "$143273582443PhrSn:example.org",
            "sender": "@alice:example.org",
            "origin_server_ts": 1432735824653u64,
            "room_id": "!636q39766251:example.org"
        });

        let deserialized: EventMeta = serde_json::from_value(json).unwrap();

        assert_eq!(deserialized.redacted, None);
    }

    #[test]
    fn test_event_meta_real_matrix_org_example() {
        // Real matrix.org style event meta
        let json = json!({
            "event_id": "$143273582443PhrSn:matrix.org",
            "sender": "@alice:matrix.org",
            "origin_server_ts": 1432735824653u64,
            "room_id": "!636q39766251:matrix.org",
            "redacted": null
        });

        let deserialized: EventMeta = serde_json::from_value(json).unwrap();

        assert_eq!(
            deserialized.event_id,
            event_id!("$143273582443PhrSn:matrix.org").to_owned()
        );
        assert_eq!(
            deserialized.sender,
            user_id!("@alice:matrix.org").to_owned()
        );
        assert_eq!(
            deserialized.timestamp,
            MilliSecondsSinceUnixEpoch(UInt::new(1432735824653u64).unwrap())
        );
        assert_eq!(
            deserialized.room_id,
            room_id!("!636q39766251:matrix.org").to_owned()
        );
        assert_eq!(deserialized.redacted, None);
    }

    #[test]
    fn test_event_meta_with_redacted_because_matrix_style() {
        // Matrix.org style event with redacted_because field
        let json = json!({
            "event_id": "$143273582443PhrSn:matrix.org",
            "sender": "@alice:matrix.org",
            "origin_server_ts": 1432735824653u64,
            "room_id": "!636q39766251:matrix.org",
            "redacted": "$redacted_event:matrix.org",
            "redacted_because": {
                "type": "m.room.redaction",
                "room_id": "!636q39766251:matrix.org",
                "sender": "@bob:matrix.org",
                "content": {
                    "reason": "Spam"
                },
                "redacts": "$143273582443PhrSn:matrix.org",
                "origin_server_ts": 1432735825000u64,
                "event_id": "$redacted_event:matrix.org"
            }
        });

        let deserialized: EventMeta = serde_json::from_value(json).unwrap();

        assert_eq!(
            deserialized.event_id,
            event_id!("$143273582443PhrSn:matrix.org").to_owned()
        );
        assert_eq!(
            deserialized.redacted,
            Some(event_id!("$redacted_event:matrix.org").to_owned())
        );
    }

    #[test]
    fn test_event_meta_with_unsigned_data_matrix_style() {
        // Matrix.org style event with unsigned data (should be ignored for EventMeta)
        let json = json!({
            "event_id": "$143273582443PhrSn:matrix.org",
            "sender": "@alice:matrix.org",
            "origin_server_ts": 1432735824653u64,
            "room_id": "!636q39766251:matrix.org",
            "unsigned": {
                "age": 123456,
                "transaction_id": "txn123"
            }
        });

        let deserialized: EventMeta = serde_json::from_value(json).unwrap();

        assert_eq!(
            deserialized.event_id,
            event_id!("$143273582443PhrSn:matrix.org").to_owned()
        );
        assert_eq!(
            deserialized.sender,
            user_id!("@alice:matrix.org").to_owned()
        );
        assert_eq!(
            deserialized.timestamp,
            MilliSecondsSinceUnixEpoch(UInt::new(1432735824653u64).unwrap())
        );
        assert_eq!(
            deserialized.room_id,
            room_id!("!636q39766251:matrix.org").to_owned()
        );
    }

    #[test]
    fn test_event_meta_with_special_characters_matrix_style() {
        // Test with special characters in IDs (common in matrix.org)
        let json = json!({
            "event_id": "$143273582443PhrSn_!@#$%^&*():matrix.org",
            "sender": "@alice_with_underscores:matrix.org",
            "origin_server_ts": 1432735824653u64,
            "room_id": "!636q39766251_with-dashes:matrix.org",
            "redacted": "$redacted_with_spaces:matrix.org"
        });

        let deserialized: EventMeta = serde_json::from_value(json).unwrap();

        assert_eq!(
            deserialized.event_id,
            event_id!("$143273582443PhrSn_!@#$%^&*():matrix.org").to_owned()
        );
        assert_eq!(
            deserialized.sender,
            user_id!("@alice_with_underscores:matrix.org").to_owned()
        );
        assert_eq!(
            deserialized.room_id,
            room_id!("!636q39766251_with-dashes:matrix.org").to_owned()
        );
        assert_eq!(
            deserialized.redacted,
            Some(event_id!("$redacted_with_spaces:matrix.org").to_owned())
        );
    }

    #[test]
    fn test_event_meta_zero_timestamp_matrix_style() {
        let event_meta = EventMeta {
            event_id: event_id!("$zero_time:matrix.org").to_owned(),
            sender: user_id!("@alice:matrix.org").to_owned(),
            timestamp: MilliSecondsSinceUnixEpoch(UInt::new(0u64).unwrap()),
            room_id: room_id!("!room:matrix.org").to_owned(),
            redacted: None,
        };

        let serialized = serde_json::to_string(&event_meta).unwrap();
        let deserialized: EventMeta = serde_json::from_str(&serialized).unwrap();

        assert_eq!(event_meta, deserialized);
        assert_eq!(
            deserialized.timestamp,
            MilliSecondsSinceUnixEpoch(UInt::new(0u64).unwrap())
        );
    }

    #[test]
    fn test_event_meta_large_timestamp_matrix_style() {
        // Test with a large timestamp (future date)
        let large_timestamp = UInt::new(1735689600000u64).unwrap(); // 2025-01-01 00:00:00 UTC
        let event_meta = EventMeta {
            event_id: event_id!("$large_time:matrix.org").to_owned(),
            sender: user_id!("@alice:matrix.org").to_owned(),
            timestamp: MilliSecondsSinceUnixEpoch(large_timestamp),
            room_id: room_id!("!room:matrix.org").to_owned(),
            redacted: None,
        };

        let serialized = serde_json::to_string(&event_meta).unwrap();
        let deserialized: EventMeta = serde_json::from_str(&serialized).unwrap();

        assert_eq!(event_meta, deserialized);
        assert_eq!(
            deserialized.timestamp,
            MilliSecondsSinceUnixEpoch(large_timestamp)
        );
    }

    #[test]
    fn test_event_meta_serialization_pretty_matrix_style() {
        let event_meta = create_matrix_style_event_meta();
        let serialized = serde_json::to_string_pretty(&event_meta).unwrap();

        // Verify it can be deserialized back
        let deserialized: EventMeta = serde_json::from_str(&serialized).unwrap();
        assert_eq!(event_meta, deserialized);
    }

    #[test]
    fn test_event_meta_from_acter_event_style() {
        // Extract just the EventMeta fields
        let event_meta_json = json!({
            "event_id": "$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c",
            "sender": "@odo:ds9.acter.global",
            "origin_server_ts": 1672407531453u64,
            "room_id": "!euhIDqDVvVXulrhWgN:ds9.acter.global",
            "redacted": null
        });

        let deserialized: EventMeta = serde_json::from_value(event_meta_json).unwrap();

        assert_eq!(
            deserialized.event_id,
            event_id!("$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c").to_owned()
        );
        assert_eq!(
            deserialized.sender,
            user_id!("@odo:ds9.acter.global").to_owned()
        );
        assert_eq!(
            deserialized.timestamp,
            MilliSecondsSinceUnixEpoch(UInt::new(1672407531453u64).unwrap())
        );
        assert_eq!(
            deserialized.room_id,
            room_id!("!euhIDqDVvVXulrhWgN:ds9.acter.global").to_owned()
        );
    }

    #[test]
    fn test_event_meta_redacted_acter_event_style() {
        // Test parsing from redacted acter event style JSON
        let event_meta_json = json!({
            "event_id": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco",
            "sender": "@emilvincentz:effektio.org",
            "origin_server_ts": 1689158713657u64,
            "room_id": "!uUufOaBOZwafrtxhoO:effektio.org",
            "redacted": "$2_k7NsG2GOGfyeNOvV55OovysVl7WGKgGEY2hv6VosY"
        });

        let deserialized: EventMeta = serde_json::from_value(event_meta_json).unwrap();

        assert_eq!(
            deserialized.event_id,
            event_id!("$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco").to_owned()
        );
        assert_eq!(
            deserialized.sender,
            user_id!("@emilvincentz:effektio.org").to_owned()
        );
        assert_eq!(
            deserialized.timestamp,
            MilliSecondsSinceUnixEpoch(UInt::new(1689158713657u64).unwrap())
        );
        assert_eq!(
            deserialized.room_id,
            room_id!("!uUufOaBOZwafrtxhoO:effektio.org").to_owned()
        );
        assert_eq!(
            deserialized.redacted,
            Some(event_id!("$2_k7NsG2GOGfyeNOvV55OovysVl7WGKgGEY2hv6VosY").to_owned())
        );
    }

    #[test]
    fn test_event_meta_error_handling() {
        // Test missing required fields
        let json = json!({
            "sender": "@alice:matrix.org",
            "origin_server_ts": 1432735824653u64,
            "room_id": "!636q39766251:matrix.org"
        });

        let result: Result<EventMeta, _> = serde_json::from_value(json);
        assert!(result.is_err());

        // Test invalid event_id format
        let json = json!({
            "event_id": "invalid_event_id",
            "sender": "@alice:matrix.org",
            "origin_server_ts": 1432735824653u64,
            "room_id": "!636q39766251:matrix.org"
        });

        let result: Result<EventMeta, _> = serde_json::from_value(json);
        assert!(result.is_err());

        // Test invalid room_id format
        let json = json!({
            "event_id": "$143273582443PhrSn:matrix.org",
            "sender": "@alice:matrix.org",
            "origin_server_ts": 1432735824653u64,
            "room_id": "invalid_room_id"
        });

        let result: Result<EventMeta, _> = serde_json::from_value(json);
        assert!(result.is_err());

        // Test invalid sender format
        let json = json!({
            "event_id": "$143273582443PhrSn:matrix.org",
            "sender": "invalid_sender",
            "origin_server_ts": 1432735824653u64,
            "room_id": "!636q39766251:matrix.org"
        });

        let result: Result<EventMeta, _> = serde_json::from_value(json);
        assert!(result.is_err());
    }
}
