use super::{
    IndexKey, ModelParam, ModelType, ObjectId, RoomId, RoomParam, SectionIndex, SpecialListsIndex,
};
use serde::{Deserialize, Serialize, de::DeserializeOwned};
use std::borrow::Cow;

#[derive(Eq, PartialEq, Ord, PartialOrd, Hash, Debug, Clone, Serialize, Deserialize)]
#[serde(
    bound = "R: Serialize + DeserializeOwned, O: Serialize + DeserializeOwned, M: Serialize + DeserializeOwned",
    rename_all = "snake_case"
)]
pub enum ExecuteReference<R, O, M>
where
    R: RoomId,
    O: ObjectId,
    M: ModelType,
{
    Index(IndexKey<R, O>),
    Model(O),
    Room(R),
    RoomAccountData(R, Cow<'static, str>),
    ModelParam(O, ModelParam),
    RoomParam(R, RoomParam),
    AccountData(Cow<'static, str>),
    ModelType(M),
}

impl<R, O, M> ExecuteReference<R, O, M>
where
    R: RoomId,
    O: ObjectId,
    M: ModelType,
{
    pub fn as_storage_key(&self) -> String {
        match self {
            ExecuteReference::Model(owned_event_id) => {
                format!("acter::{}", owned_event_id.as_ref())
            }
            ExecuteReference::ModelParam(owned_event_id, model_param) => {
                format!("{}::{}", owned_event_id.as_ref(), model_param)
            }
            ExecuteReference::RoomParam(owned_room_id, room_param) => {
                format!("{}::{}", owned_room_id.as_ref(), room_param)
            }
            ExecuteReference::ModelType(model_type) => model_type.as_ref().to_string(),
            ExecuteReference::Index(IndexKey::Special(SpecialListsIndex::InvitedTo)) => {
                "global_invited".to_owned() // this is a special case, we actively store and manage
            }
            // not actually supported
            ExecuteReference::Index(_index_key) => todo!(),
            ExecuteReference::Room(_owned_room_id) => todo!(),
            ExecuteReference::RoomAccountData(_owned_room_id, _cow) => todo!(),
            ExecuteReference::AccountData(_cow) => todo!(),
        }
    }
}


impl<R, O, M> From<IndexKey<R, O>> for ExecuteReference<R, O, M>
where
    R: RoomId,
    O: ObjectId,
    M: ModelType,
{
    fn from(value: IndexKey<R, O>) -> Self {
        ExecuteReference::Index(value)
    }
}

impl<R, O, M> From<SectionIndex> for ExecuteReference<R, O, M>
where
    R: RoomId,
    O: ObjectId,
    M: ModelType,
{
    fn from(value: SectionIndex) -> Self {
        ExecuteReference::Index(IndexKey::Section(value))
    }
}


#[cfg(test)]
mod tests {
    use super::super::ObjectListIndex;

    use super::*;
    use serde_json;

    // Helper function to test round-trip serialization/deserialization
    fn test_round_trip<T>(value: &T) -> Result<(), Box<dyn std::error::Error>>
    where
        T: Serialize + for<'de> Deserialize<'de> + PartialEq + std::fmt::Debug,
    {
        let serialized = serde_json::to_string(value)?;
        let deserialized: T = serde_json::from_str(&serialized)?;
        assert_eq!(value, &deserialized);
        Ok(())
    }

    // Mock types for testing
    #[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
    struct MockRoomId(String);

    impl AsRef<str> for MockRoomId {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }

    #[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
    struct MockObjectId(String);

    impl AsRef<str> for MockObjectId {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }

    #[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
    struct MockModelType(String);

    impl AsRef<str> for MockModelType {
        fn as_ref(&self) -> &str {
            &self.0
        }
    }

    type TestExecuteReference = ExecuteReference<MockRoomId, MockObjectId, MockModelType>;

    #[test]
    fn test_index_variant_serialization() -> Result<(), Box<dyn std::error::Error>> {
        // Test RoomHistory variant
        let room_id = MockRoomId("!test:example.org".to_string());
        let index_key = IndexKey::RoomHistory(room_id.clone());
        let execute_ref = TestExecuteReference::Index(index_key);
        test_round_trip(&execute_ref)?;

        // Test RoomModels variant
        let index_key = IndexKey::RoomModels(room_id.clone());
        let execute_ref = TestExecuteReference::Index(index_key);
        test_round_trip(&execute_ref)?;

        // Test ObjectHistory variant
        let object_id = MockObjectId("$test_event_id".to_string());
        let index_key = IndexKey::ObjectHistory(object_id.clone());
        let execute_ref = TestExecuteReference::Index(index_key);
        test_round_trip(&execute_ref)?;

        // Test Section variant
        let index_key = IndexKey::Section(SectionIndex::Boosts);
        let execute_ref = TestExecuteReference::Index(index_key);
        test_round_trip(&execute_ref)?;

        // Test RoomSection variant
        let index_key = IndexKey::RoomSection(room_id.clone(), SectionIndex::Tasks);
        let execute_ref = TestExecuteReference::Index(index_key);
        test_round_trip(&execute_ref)?;

        // Test ObjectList variant
        let index_key = IndexKey::ObjectList(object_id.clone(), ObjectListIndex::Comments);
        let execute_ref = TestExecuteReference::Index(index_key);
        test_round_trip(&execute_ref)?;

        // Test Special variant
        let index_key = IndexKey::Special(SpecialListsIndex::InvitedTo);
        let execute_ref = TestExecuteReference::Index(index_key);
        test_round_trip(&execute_ref)?;

        // Test Redacted variant
        let index_key = IndexKey::Redacted;
        let execute_ref = TestExecuteReference::Index(index_key);
        test_round_trip(&execute_ref)?;

        // Test AllHistory variant
        let index_key = IndexKey::AllHistory;
        let execute_ref = TestExecuteReference::Index(index_key);
        test_round_trip(&execute_ref)?;

        Ok(())
    }

    #[test]
    fn test_model_variant_serialization() -> Result<(), Box<dyn std::error::Error>> {
        let object_id = MockObjectId("$test_event_id".to_string());
        let execute_ref = TestExecuteReference::Model(object_id);
        test_round_trip(&execute_ref)?;
        Ok(())
    }

    #[test]
    fn test_room_variant_serialization() -> Result<(), Box<dyn std::error::Error>> {
        let room_id = MockRoomId("!test:example.org".to_string());
        let execute_ref = TestExecuteReference::Room(room_id);
        test_round_trip(&execute_ref)?;
        Ok(())
    }

    #[test]
    fn test_room_account_data_variant_serialization() -> Result<(), Box<dyn std::error::Error>> {
        let room_id = MockRoomId("!test:example.org".to_string());
        let account_data = Cow::Borrowed("test_account_data");
        let execute_ref = TestExecuteReference::RoomAccountData(room_id, account_data);
        test_round_trip(&execute_ref)?;

        // Test with owned string
        let room_id = MockRoomId("!test2:example.org".to_string());
        let account_data = Cow::Owned("owned_account_data".to_string());
        let execute_ref = TestExecuteReference::RoomAccountData(room_id, account_data);
        test_round_trip(&execute_ref)?;
        Ok(())
    }

    #[test]
    fn test_model_param_variant_serialization() -> Result<(), Box<dyn std::error::Error>> {
        let object_id = MockObjectId("$test_event_id".to_string());

        // Test all ModelParam variants
        for model_param in [
            ModelParam::CommentsStats,
            ModelParam::AttachmentsStats,
            ModelParam::ReactionStats,
            ModelParam::RsvpStats,
            ModelParam::ReadReceiptsStats,
            ModelParam::InviteStats,
        ] {
            let execute_ref = TestExecuteReference::ModelParam(object_id.clone(), model_param);
            test_round_trip(&execute_ref)?;
        }
        Ok(())
    }

    #[test]
    fn test_room_param_variant_serialization() -> Result<(), Box<dyn std::error::Error>> {
        let room_id = MockRoomId("!test:example.org".to_string());

        // Test all RoomParam variants
        {
            let room_param = RoomParam::LatestMessage;
            let execute_ref = TestExecuteReference::RoomParam(room_id.clone(), room_param);
            test_round_trip(&execute_ref)?;
        }
        Ok(())
    }

    #[test]
    fn test_account_data_variant_serialization() -> Result<(), Box<dyn std::error::Error>> {
        // Test with borrowed string
        let account_data = Cow::Borrowed("test_account_data");
        let execute_ref = TestExecuteReference::AccountData(account_data);
        test_round_trip(&execute_ref)?;

        // Test with owned string
        let account_data = Cow::Owned("owned_account_data".to_string());
        let execute_ref = TestExecuteReference::AccountData(account_data);
        test_round_trip(&execute_ref)?;
        Ok(())
    }

    #[test]
    fn test_model_type_variant_serialization() -> Result<(), Box<dyn std::error::Error>> {
        let model_type = MockModelType("test_model_type".to_string());
        let execute_ref = TestExecuteReference::ModelType(model_type);
        test_round_trip(&execute_ref)?;
        Ok(())
    }

    #[test]
    fn test_all_variants_serialization() -> Result<(), Box<dyn std::error::Error>> {
        let room_id = MockRoomId("!test:example.org".to_string());
        let object_id = MockObjectId("$test_event_id".to_string());
        let model_type = MockModelType("test_model_type".to_string());

        // Test all variants in one comprehensive test
        let variants = vec![
            TestExecuteReference::Index(IndexKey::RoomHistory(room_id.clone())),
            TestExecuteReference::Index(IndexKey::RoomModels(room_id.clone())),
            TestExecuteReference::Index(IndexKey::ObjectHistory(object_id.clone())),
            TestExecuteReference::Index(IndexKey::Section(SectionIndex::Boosts)),
            TestExecuteReference::Index(IndexKey::RoomSection(
                room_id.clone(),
                SectionIndex::Tasks,
            )),
            TestExecuteReference::Index(IndexKey::ObjectList(
                object_id.clone(),
                ObjectListIndex::Comments,
            )),
            TestExecuteReference::Index(IndexKey::Special(SpecialListsIndex::InvitedTo)),
            TestExecuteReference::Index(IndexKey::Redacted),
            TestExecuteReference::Index(IndexKey::AllHistory),
            TestExecuteReference::Model(object_id.clone()),
            TestExecuteReference::Room(room_id.clone()),
            TestExecuteReference::RoomAccountData(room_id.clone(), Cow::Borrowed("test_data")),
            TestExecuteReference::ModelParam(object_id.clone(), ModelParam::CommentsStats),
            TestExecuteReference::RoomParam(room_id.clone(), RoomParam::LatestMessage),
            TestExecuteReference::AccountData(Cow::Borrowed("test_account_data")),
            TestExecuteReference::ModelType(model_type),
        ];

        for variant in variants {
            test_round_trip(&variant)?;
        }
        Ok(())
    }

    #[test]
    fn test_from_parsers() {
        let room_id = MockRoomId("!test:example.org".to_string());
        let object_id = MockObjectId("$test_event_id".to_string());

        // Test From<IndexKey<R, O>> implementation
        let index_key = IndexKey::RoomHistory(room_id.clone());
        let execute_ref: TestExecuteReference = index_key.clone().into();
        assert!(matches!(execute_ref, TestExecuteReference::Index(_)));
        if let TestExecuteReference::Index(ik) = execute_ref {
            assert_eq!(ik, index_key);
        }

        // Test From<SectionIndex> implementation
        let section_index = SectionIndex::Boosts;
        let execute_ref: TestExecuteReference = section_index.into();
        assert!(matches!(
            execute_ref,
            TestExecuteReference::Index(IndexKey::Section(_))
        ));
        if let TestExecuteReference::Index(IndexKey::Section(si)) = execute_ref {
            assert_eq!(si, SectionIndex::Boosts);
        }

        // Test From<SectionIndex> with different variants
        for section_index in [
            SectionIndex::Boosts,
            SectionIndex::Calendar,
            SectionIndex::Pins,
            SectionIndex::Stories,
            SectionIndex::Tasks,
        ] {
            let execute_ref: TestExecuteReference = section_index.clone().into();
            assert!(matches!(
                execute_ref,
                TestExecuteReference::Index(IndexKey::Section(_))
            ));
            if let TestExecuteReference::Index(IndexKey::Section(si)) = execute_ref {
                assert_eq!(si, section_index);
            }
        }

        // Test From<IndexKey<R, O>> with different variants
        let index_variants = vec![
            IndexKey::RoomHistory(room_id.clone()),
            IndexKey::RoomModels(room_id.clone()),
            IndexKey::ObjectHistory(object_id.clone()),
            IndexKey::Section(SectionIndex::Boosts),
            IndexKey::RoomSection(room_id.clone(), SectionIndex::Tasks),
            IndexKey::ObjectList(object_id.clone(), ObjectListIndex::Comments),
            IndexKey::Special(SpecialListsIndex::InvitedTo),
            IndexKey::Redacted,
            IndexKey::AllHistory,
        ];

        for index_key in index_variants {
            let execute_ref: TestExecuteReference = index_key.clone().into();
            assert!(matches!(execute_ref, TestExecuteReference::Index(_)));
            if let TestExecuteReference::Index(ik) = execute_ref {
                assert_eq!(ik, index_key);
            }
        }
    }

    #[test]
    fn test_as_storage_key() {
        let room_id = MockRoomId("!test:example.org".to_string());
        let object_id = MockObjectId("$test_event_id".to_string());
        let model_type = MockModelType("test_model_type".to_string());

        // Test Model variant
        let execute_ref = TestExecuteReference::Model(object_id.clone());
        let storage_key = execute_ref.as_storage_key();
        assert_eq!(storage_key, "acter::$test_event_id");

        // Test ModelParam variants
        for model_param in [
            ModelParam::CommentsStats,
            ModelParam::AttachmentsStats,
            ModelParam::ReactionStats,
            ModelParam::RsvpStats,
            ModelParam::ReadReceiptsStats,
            ModelParam::InviteStats,
        ] {
            let execute_ref =
                TestExecuteReference::ModelParam(object_id.clone(), model_param.clone());
            let storage_key = execute_ref.as_storage_key();
            assert_eq!(storage_key, format!("$test_event_id::{}", model_param));
        }

        // Test RoomParam variants
        {
            let room_param = RoomParam::LatestMessage;
            let execute_ref = TestExecuteReference::RoomParam(room_id.clone(), room_param.clone());
            let storage_key = execute_ref.as_storage_key();
            assert_eq!(storage_key, format!("!test:example.org::{}", room_param));
        }

        // Test ModelType variant
        let execute_ref = TestExecuteReference::ModelType(model_type.clone());
        let storage_key = execute_ref.as_storage_key();
        assert_eq!(storage_key, "test_model_type");

        // Test Index with SpecialListsIndex::InvitedTo
        let index_key = IndexKey::Special(SpecialListsIndex::InvitedTo);
        let execute_ref = TestExecuteReference::Index(index_key);
        let storage_key = execute_ref.as_storage_key();
        assert_eq!(storage_key, "global_invited");

        // Test that other Index variants panic (as they are marked as todo!)
        let index_key = IndexKey::RoomHistory(room_id.clone());
        let execute_ref = TestExecuteReference::Index(index_key);
        let result = std::panic::catch_unwind(|| execute_ref.as_storage_key());
        assert!(result.is_err());

        // Test that Room variant panics (as it is marked as todo!)
        let execute_ref = TestExecuteReference::Room(room_id.clone());
        let result = std::panic::catch_unwind(|| execute_ref.as_storage_key());
        assert!(result.is_err());

        // Test that RoomAccountData variant panics (as it is marked as todo!)
        let execute_ref =
            TestExecuteReference::RoomAccountData(room_id.clone(), Cow::Borrowed("test"));
        let result = std::panic::catch_unwind(|| execute_ref.as_storage_key());
        assert!(result.is_err());

        // Test that AccountData variant panics (as it is marked as todo!)
        let execute_ref = TestExecuteReference::AccountData(Cow::Borrowed("test"));
        let result = std::panic::catch_unwind(|| execute_ref.as_storage_key());
        assert!(result.is_err());
    }

    #[test]
    fn test_as_storage_key_edge_cases() {
        // Test with empty strings
        let room_id = MockRoomId("".to_string());
        let object_id = MockObjectId("".to_string());
        let model_type = MockModelType("".to_string());

        let execute_ref = TestExecuteReference::Model(object_id.clone());
        let storage_key = execute_ref.as_storage_key();
        assert_eq!(storage_key, "acter::");

        let execute_ref =
            TestExecuteReference::ModelParam(object_id.clone(), ModelParam::CommentsStats);
        let storage_key = execute_ref.as_storage_key();
        assert_eq!(storage_key, "::comments_stats");

        let execute_ref =
            TestExecuteReference::RoomParam(room_id.clone(), RoomParam::LatestMessage);
        let storage_key = execute_ref.as_storage_key();
        assert_eq!(storage_key, "::latest_message");

        let execute_ref = TestExecuteReference::ModelType(model_type.clone());
        let storage_key = execute_ref.as_storage_key();
        assert_eq!(storage_key, "");

        // Test with special characters
        let room_id = MockRoomId("!test@#$%^&*():example.org".to_string());
        let object_id = MockObjectId("$test@#$%^&*()_event_id".to_string());
        let model_type = MockModelType("test@#$%^&*()_model_type".to_string());

        let execute_ref = TestExecuteReference::Model(object_id.clone());
        let storage_key = execute_ref.as_storage_key();
        assert_eq!(storage_key, "acter::$test@#$%^&*()_event_id");

        let execute_ref =
            TestExecuteReference::ModelParam(object_id.clone(), ModelParam::CommentsStats);
        let storage_key = execute_ref.as_storage_key();
        assert_eq!(storage_key, "$test@#$%^&*()_event_id::comments_stats");

        let execute_ref =
            TestExecuteReference::RoomParam(room_id.clone(), RoomParam::LatestMessage);
        let storage_key = execute_ref.as_storage_key();
        assert_eq!(storage_key, "!test@#$%^&*():example.org::latest_message");

        let execute_ref = TestExecuteReference::ModelType(model_type.clone());
        let storage_key = execute_ref.as_storage_key();
        assert_eq!(storage_key, "test@#$%^&*()_model_type");
    }

    #[test]
    fn test_from_parsers_comprehensive() {
        let room_id = MockRoomId("!test:example.org".to_string());
        let object_id = MockObjectId("$test_event_id".to_string());

        // Test all From implementations with different data types
        let test_cases = vec![
            // From<M>
            //
            // From<IndexKey<R, O>> - RoomHistory
            (
                IndexKey::RoomHistory(room_id.clone()),
                TestExecuteReference::Index(IndexKey::RoomHistory(room_id.clone())),
            ),
            // From<IndexKey<R, O>> - RoomModels
            (
                IndexKey::RoomModels(room_id.clone()),
                TestExecuteReference::Index(IndexKey::RoomModels(room_id.clone())),
            ),
            // From<IndexKey<R, O>> - ObjectHistory
            (
                IndexKey::ObjectHistory(object_id.clone()),
                TestExecuteReference::Index(IndexKey::ObjectHistory(object_id.clone())),
            ),
            // From<IndexKey<R, O>> - Section
            (
                IndexKey::Section(SectionIndex::Boosts),
                TestExecuteReference::Index(IndexKey::Section(SectionIndex::Boosts)),
            ),
            // From<IndexKey<R, O>> - RoomSection
            (
                IndexKey::RoomSection(room_id.clone(), SectionIndex::Tasks),
                TestExecuteReference::Index(IndexKey::RoomSection(
                    room_id.clone(),
                    SectionIndex::Tasks,
                )),
            ),
            // From<IndexKey<R, O>> - ObjectList
            (
                IndexKey::ObjectList(object_id.clone(), ObjectListIndex::Comments),
                TestExecuteReference::Index(IndexKey::ObjectList(
                    object_id.clone(),
                    ObjectListIndex::Comments,
                )),
            ),
            // From<IndexKey<R, O>> - Special
            (
                IndexKey::Special(SpecialListsIndex::InvitedTo),
                TestExecuteReference::Index(IndexKey::Special(SpecialListsIndex::InvitedTo)),
            ),
            // From<IndexKey<R, O>> - Redacted
            (
                IndexKey::Redacted,
                TestExecuteReference::Index(IndexKey::Redacted),
            ),
            // From<IndexKey<R, O>> - AllHistory
            (
                IndexKey::AllHistory,
                TestExecuteReference::Index(IndexKey::AllHistory),
            ),
        ];

        for (input, expected) in test_cases {
            let result: TestExecuteReference = input.into();
            assert_eq!(result, expected);
        }

        // Test From<SectionIndex> specifically
        for section_index in [
            SectionIndex::Boosts,
            SectionIndex::Calendar,
            SectionIndex::Pins,
            SectionIndex::Stories,
            SectionIndex::Tasks,
        ] {
            let result: TestExecuteReference = section_index.clone().into();
            let expected = TestExecuteReference::Index(IndexKey::Section(section_index));
            assert_eq!(result, expected);
        }
    }
}
