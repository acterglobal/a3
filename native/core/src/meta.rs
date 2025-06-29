use crate::traits::TypeConfig;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(any(test, feature = "testing"), derive(PartialEq, Eq))]
pub struct EventMeta<C>
where
    C: TypeConfig,
{
    /// The globally unique event identifier attached to this event
    pub event_id: C::ObjectId,

    /// The fully-qualified ID of the user who sent created this event
    pub sender: C::UserId,

    /// Timestamp in milliseconds on originating homeserver when the event was created
    #[serde(alias = "origin_server_ts")]
    pub timestamp: C::Timestamp,

    /// The ID of the room of this event
    pub room_id: C::RoomId,

    /// Optional redacted event identifier
    #[serde(default)]
    pub redacted: Option<C::ObjectId>,
}

#[cfg(test)]
mod tests {
    use crate::mocks::MockError;

    use super::*;
    use serde_json;
    use std::hash::Hash;

    // Test implementation of TypeConfig for testing
    #[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, Hash)]
    struct TestConfig;

    impl TypeConfig for TestConfig {
        type RoomId = String;
        type ObjectId = String;
        type ModelType = String;
        type AccountData = String;
        type UserId = String;
        type Timestamp = u64;
        type RedactionReason = String;
        type Error = MockError;
    }

    #[test]
    fn test_event_meta_serialization() {
        let event_meta = EventMeta::<TestConfig> {
            event_id: "$event123".to_string(),
            sender: "@user:example.com".to_string(),
            timestamp: 1640995200000, // 2022-01-01 00:00:00 UTC
            room_id: "!room123:example.com".to_string(),
            redacted: None,
        };

        let serialized = serde_json::to_string(&event_meta).unwrap();
        let expected = r#"{"event_id":"$event123","sender":"@user:example.com","timestamp":1640995200000,"room_id":"!room123:example.com","redacted":null}"#;

        assert_eq!(serialized, expected);
    }

    #[test]
    fn test_event_meta_deserialization() {
        let json = r#"{
            "event_id": "$event456",
            "sender": "@alice:matrix.org",
            "timestamp": 1640995200000,
            "room_id": "!room456:matrix.org",
            "redacted": null
        }"#;

        let deserialized: EventMeta<TestConfig> = serde_json::from_str(json).unwrap();

        assert_eq!(deserialized.event_id, "$event456");
        assert_eq!(deserialized.sender, "@alice:matrix.org");
        assert_eq!(deserialized.timestamp, 1640995200000);
        assert_eq!(deserialized.room_id, "!room456:matrix.org");
        assert_eq!(deserialized.redacted, None);
    }

    #[test]
    fn test_event_meta_with_redacted_event() {
        let event_meta = EventMeta::<TestConfig> {
            event_id: "$event789".to_string(),
            sender: "@bob:example.com".to_string(),
            timestamp: 1640995200000,
            room_id: "!room789:example.com".to_string(),
            redacted: Some("$redacted_event".to_string()),
        };

        let serialized = serde_json::to_string(&event_meta).unwrap();
        let deserialized: EventMeta<TestConfig> = serde_json::from_str(&serialized).unwrap();

        assert_eq!(event_meta, deserialized);
        assert_eq!(deserialized.redacted, Some("$redacted_event".to_string()));
    }

    #[test]
    fn test_event_meta_timestamp_alias() {
        // Test that the "origin_server_ts" alias works for deserialization
        let json = r#"{
            "event_id": "$event123",
            "sender": "@user:example.com",
            "origin_server_ts": 1640995200000,
            "room_id": "!room123:example.com"
        }"#;

        let deserialized: EventMeta<TestConfig> = serde_json::from_str(json).unwrap();

        assert_eq!(deserialized.timestamp, 1640995200000);
    }

    #[test]
    fn test_event_meta_roundtrip() {
        let original = EventMeta::<TestConfig> {
            event_id: "$event_roundtrip".to_string(),
            sender: "@test:example.com".to_string(),
            timestamp: 1640995200000,
            room_id: "!room_roundtrip:example.com".to_string(),
            redacted: Some("$redacted_roundtrip".to_string()),
        };

        let serialized = serde_json::to_string(&original).unwrap();
        let deserialized: EventMeta<TestConfig> = serde_json::from_str(&serialized).unwrap();

        assert_eq!(original, deserialized);
    }

    #[test]
    fn test_event_meta_missing_redacted_field() {
        // Test that missing redacted field defaults to None
        let json = r#"{
            "event_id": "$event123",
            "sender": "@user:example.com",
            "timestamp": 1640995200000,
            "room_id": "!room123:example.com"
        }"#;

        let deserialized: EventMeta<TestConfig> = serde_json::from_str(json).unwrap();

        assert_eq!(deserialized.redacted, None);
    }

    #[test]
    fn test_event_meta_empty_redacted_field() {
        // Test that empty redacted field is handled correctly
        let json = r#"{
            "event_id": "$event123",
            "sender": "@user:example.com",
            "timestamp": 1640995200000,
            "room_id": "!room123:example.com",
            "redacted": ""
        }"#;

        let deserialized: EventMeta<TestConfig> = serde_json::from_str(json).unwrap();

        assert_eq!(deserialized.redacted, Some("".to_string()));
    }

    #[test]
    fn test_event_meta_serialization_pretty() {
        let event_meta = EventMeta::<TestConfig> {
            event_id: "$event_pretty".to_string(),
            sender: "@user:example.com".to_string(),
            timestamp: 1640995200000,
            room_id: "!room_pretty:example.com".to_string(),
            redacted: Some("$redacted_pretty".to_string()),
        };

        let serialized = serde_json::to_string_pretty(&event_meta).unwrap();

        // Verify it can be deserialized back
        let deserialized: EventMeta<TestConfig> = serde_json::from_str(&serialized).unwrap();
        assert_eq!(event_meta, deserialized);
    }

    #[test]
    fn test_event_meta_with_special_characters() {
        let event_meta = EventMeta::<TestConfig> {
            event_id: "$event_with_special_chars_!@#$%^&*()".to_string(),
            sender: "@user_with_underscores:example.com".to_string(),
            timestamp: 1640995200000,
            room_id: "!room_with_dashes:example.com".to_string(),
            redacted: Some("$redacted_with_spaces".to_string()),
        };

        let serialized = serde_json::to_string(&event_meta).unwrap();
        let deserialized: EventMeta<TestConfig> = serde_json::from_str(&serialized).unwrap();

        assert_eq!(event_meta, deserialized);
    }

    #[test]
    fn test_event_meta_zero_timestamp() {
        let event_meta = EventMeta::<TestConfig> {
            event_id: "$event_zero_time".to_string(),
            sender: "@user:example.com".to_string(),
            timestamp: 0,
            room_id: "!room:example.com".to_string(),
            redacted: None,
        };

        let serialized = serde_json::to_string(&event_meta).unwrap();
        let deserialized: EventMeta<TestConfig> = serde_json::from_str(&serialized).unwrap();

        assert_eq!(event_meta, deserialized);
        assert_eq!(deserialized.timestamp, 0);
    }

    #[test]
    fn test_event_meta_large_timestamp() {
        let event_meta = EventMeta::<TestConfig> {
            event_id: "$event_large_time".to_string(),
            sender: "@user:example.com".to_string(),
            timestamp: u64::MAX,
            room_id: "!room:example.com".to_string(),
            redacted: None,
        };

        let serialized = serde_json::to_string(&event_meta).unwrap();
        let deserialized: EventMeta<TestConfig> = serde_json::from_str(&serialized).unwrap();

        assert_eq!(event_meta, deserialized);
        assert_eq!(deserialized.timestamp, u64::MAX);
    }
}
