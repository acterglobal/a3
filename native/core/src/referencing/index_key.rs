use super::{ObjectListIndex, SectionIndex, SpecialListsIndex};
use crate::traits::TypeConfig;
use serde::{Deserialize, Serialize, de::DeserializeOwned};

// We organize our Index by typed keys
#[derive(Eq, PartialEq, Ord, PartialOrd, Hash, Debug, Clone, Serialize, Deserialize)]
#[serde(
    bound = "C: TypeConfig, C::RoomId: Serialize + DeserializeOwned, C::ObjectId: Serialize + DeserializeOwned",
    rename_all = "snake_case"
)]
pub enum IndexKey<C>
where
    C: TypeConfig,
{
    RoomHistory(C::RoomId),
    RoomModels(C::RoomId),
    ObjectHistory(C::ObjectId),
    Section(SectionIndex),
    RoomSection(C::RoomId, SectionIndex),
    ObjectList(C::ObjectId, ObjectListIndex),
    Special(SpecialListsIndex),
    Redacted,
    AllHistory,
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json;

    #[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
    struct MockTypeConfig;

    impl TypeConfig for MockTypeConfig {
        type RoomId = String;
        type ObjectId = String;
        type ModelType = String;
        type AccountData = String;
        type UserId = String;
        type Timestamp = String;
    }

    type TestIndexKey = IndexKey<MockTypeConfig>;

    // Helper function to test round-trip serialization/deserialization
    fn test_round_trip<T>(value: &T) -> T
    where
        T: Serialize + DeserializeOwned + PartialEq + std::fmt::Debug,
    {
        let serialized = serde_json::to_string(value).expect("Failed to serialize");
        let deserialized: T = serde_json::from_str(&serialized).expect("Failed to deserialize");
        assert_eq!(value, &deserialized);
        deserialized
    }

    #[test]
    fn test_room_history_serialization() {
        let room_id = "room123".to_string();
        let index_key = TestIndexKey::RoomHistory(room_id.clone());

        let result = test_round_trip(&index_key);
        assert!(matches!(result, IndexKey::RoomHistory(r) if r == room_id));
    }

    #[test]
    fn test_room_models_serialization() {
        let room_id = "room456".to_string();
        let index_key = TestIndexKey::RoomModels(room_id.clone());

        let result = test_round_trip(&index_key);
        assert!(matches!(result, IndexKey::RoomModels(r) if r == room_id));
    }

    #[test]
    fn test_object_history_serialization() {
        let object_id = "object789".to_string();
        let index_key = TestIndexKey::ObjectHistory(object_id.clone());

        let result = test_round_trip(&index_key);
        assert!(matches!(result, IndexKey::ObjectHistory(o) if o == object_id));
    }

    #[test]
    fn test_section_serialization() {
        let section = SectionIndex::Boosts;
        let index_key = TestIndexKey::Section(section);

        let result = test_round_trip(&index_key);
        assert!(matches!(result, IndexKey::Section(SectionIndex::Boosts)));
    }

    #[test]
    fn test_section_all_variants() {
        let sections = vec![
            SectionIndex::Boosts,
            SectionIndex::Calendar,
            SectionIndex::Pins,
            SectionIndex::Stories,
            SectionIndex::Tasks,
        ];

        for section in sections {
            let index_key = TestIndexKey::Section(section);
            let result = test_round_trip(&index_key);
            assert!(matches!(result, IndexKey::Section(_)));
        }
    }

    #[test]
    fn test_room_section_serialization() {
        let room_id = "room101".to_string();
        let section = SectionIndex::Calendar;
        let index_key = TestIndexKey::RoomSection(room_id.clone(), section);

        let result = test_round_trip(&index_key);
        assert!(matches!(result, IndexKey::RoomSection(r, SectionIndex::Calendar) if r == room_id));
    }

    #[test]
    fn test_object_list_serialization() {
        let object_id = "object202".to_string();
        let list_index = ObjectListIndex::Comments;
        let index_key = TestIndexKey::ObjectList(object_id.clone(), list_index);

        let result = test_round_trip(&index_key);
        assert!(
            matches!(result, IndexKey::ObjectList(o, ObjectListIndex::Comments) if o == object_id)
        );
    }

    #[test]
    fn test_object_list_all_variants() {
        let object_id = "object303".to_string();
        let list_indices = vec![
            ObjectListIndex::Attachments,
            ObjectListIndex::Comments,
            ObjectListIndex::Reactions,
            ObjectListIndex::ReadReceipt,
            ObjectListIndex::Rsvp,
            ObjectListIndex::Tasks,
            ObjectListIndex::Invites,
        ];

        for list_index in list_indices {
            let index_key = TestIndexKey::ObjectList(object_id.clone(), list_index);
            let result = test_round_trip(&index_key);
            assert!(matches!(result, IndexKey::ObjectList(_, _)));
        }
    }

    #[test]
    fn test_special_serialization() {
        let special_index = SpecialListsIndex::MyOpenTasks;
        let index_key = TestIndexKey::Special(special_index);

        let result = test_round_trip(&index_key);
        assert!(matches!(
            result,
            IndexKey::Special(SpecialListsIndex::MyOpenTasks)
        ));
    }

    #[test]
    fn test_special_all_variants() {
        let special_indices = vec![
            SpecialListsIndex::MyOpenTasks,
            SpecialListsIndex::MyDoneTasks,
            SpecialListsIndex::InvitedTo,
        ];

        for special_index in special_indices {
            let index_key = TestIndexKey::Special(special_index);
            let result = test_round_trip(&index_key);
            assert!(matches!(result, IndexKey::Special(_)));
        }
    }

    #[test]
    fn test_redacted_serialization() {
        let index_key = TestIndexKey::Redacted;

        let result = test_round_trip(&index_key);
        assert!(matches!(result, IndexKey::Redacted));
    }

    #[test]
    fn test_all_history_serialization() {
        let index_key = TestIndexKey::AllHistory;

        let result = test_round_trip(&index_key);
        assert!(matches!(result, IndexKey::AllHistory));
    }

    #[test]
    fn test_all_variants_round_trip() {
        let room_id = "test_room".to_string();
        let object_id = "test_object".to_string();

        let test_cases = vec![
            TestIndexKey::RoomHistory(room_id.clone()),
            TestIndexKey::RoomModels(room_id.clone()),
            TestIndexKey::ObjectHistory(object_id.clone()),
            TestIndexKey::Section(SectionIndex::Boosts),
            TestIndexKey::RoomSection(room_id.clone(), SectionIndex::Calendar),
            TestIndexKey::ObjectList(object_id.clone(), ObjectListIndex::Comments),
            TestIndexKey::Special(SpecialListsIndex::MyOpenTasks),
            TestIndexKey::Redacted,
            TestIndexKey::AllHistory,
        ];

        for (i, test_case) in test_cases.into_iter().enumerate() {
            let result = test_round_trip(&test_case);
            assert_eq!(test_case, result, "failed to round trip variant {i}");
        }
    }

    #[test]
    fn test_serialization_format() {
        let room_id = "test_room".to_string();

        // Test that the serialized format is as expected
        let room_history = TestIndexKey::RoomHistory(room_id.clone());
        let serialized = serde_json::to_string(&room_history).expect("Failed to serialize");
        assert!(serialized.contains("room_history"));
        assert!(serialized.contains(&room_id));

        let section = TestIndexKey::Section(SectionIndex::Boosts);
        let serialized = serde_json::to_string(&section).expect("Failed to serialize");
        assert!(serialized.contains("section"));
        assert!(serialized.contains("boosts"));

        let redacted = TestIndexKey::Redacted;
        let serialized = serde_json::to_string(&redacted).expect("Failed to serialize");
        assert!(serialized.contains("redacted"));
    }

    #[test]
    fn test_deserialization_errors() {
        // Test invalid JSON
        let invalid_json = r#"{"invalid": "data"}"#;
        let result: Result<TestIndexKey, _> = serde_json::from_str(invalid_json);
        assert!(result.is_err());

        // Test missing variant
        let invalid_json = r#"{"NonExistentVariant": "data"}"#;
        let result: Result<TestIndexKey, _> = serde_json::from_str(invalid_json);
        assert!(result.is_err());
    }

    #[test]
    fn test_with_custom_types() {
        // Test with custom types that implement the required traits
        #[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
        struct CustomRoomId(String);

        #[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
        struct CustomObjectId(String);

        impl AsRef<str> for CustomRoomId {
            fn as_ref(&self) -> &str {
                &self.0
            }
        }

        impl AsRef<str> for CustomObjectId {
            fn as_ref(&self) -> &str {
                &self.0
            }
        }
        #[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
        struct CustomTypeConfig;

        impl TypeConfig for CustomTypeConfig {
            type RoomId = CustomRoomId;
            type ObjectId = CustomObjectId;
            type ModelType = String;
            type AccountData = String;
            type UserId = String;
            type Timestamp = String;
        }

        type CustomIndexKey = IndexKey<CustomTypeConfig>;

        let room_id = CustomRoomId("custom_room".to_string());
        let object_id = CustomObjectId("custom_object".to_string());

        assert_eq!(room_id.as_ref(), "custom_room");
        assert_eq!(object_id.as_ref(), "custom_object");

        let test_cases = vec![
            CustomIndexKey::RoomHistory(room_id.clone()),
            CustomIndexKey::RoomModels(room_id.clone()),
            CustomIndexKey::ObjectHistory(object_id.clone()),
            CustomIndexKey::Section(SectionIndex::Tasks),
            CustomIndexKey::RoomSection(room_id.clone(), SectionIndex::Pins),
            CustomIndexKey::ObjectList(object_id.clone(), ObjectListIndex::Reactions),
            CustomIndexKey::Special(SpecialListsIndex::MyDoneTasks),
            CustomIndexKey::Redacted,
            CustomIndexKey::AllHistory,
        ];

        for test_case in test_cases {
            let result = test_round_trip(&test_case);
            assert_eq!(test_case, result);
        }
    }
}
