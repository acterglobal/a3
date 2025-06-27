use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

use crate::execution::{Model, Store};
use crate::{config::TypeConfig, referencing::ExecuteReference};

// Mock types for testing
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct MockRoomId(pub String);

impl AsRef<str> for MockRoomId {
    fn as_ref(&self) -> &str {
        &self.0
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct MockObjectId(pub String);

impl AsRef<str> for MockObjectId {
    fn as_ref(&self) -> &str {
        &self.0
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct MockModelType(pub String);

impl AsRef<str> for MockModelType {
    fn as_ref(&self) -> &str {
        &self.0
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct MockTypeConfig;

impl TypeConfig for MockTypeConfig {
    type RoomId = MockRoomId;
    type ObjectId = MockObjectId;
    type ModelType = MockModelType;
    type AccountData = String;
    type UserId = String;
    type Timestamp = String;
}

// Mock model for testing
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct MockModel {
    pub id: MockObjectId,
    pub value: i32,
    pub parent_ids: Option<Vec<MockObjectId>>,
    pub transition_count: i32,
}

impl MockModel {
    pub fn new(id: &str, value: i32, parent_ids: Option<Vec<&str>>) -> Self {
        Self {
            id: MockObjectId(id.to_string()),
            value,
            parent_ids: parent_ids.map(|ids| {
                ids.into_iter()
                    .map(|id| MockObjectId(id.to_string()))
                    .collect()
            }),
            transition_count: 0,
        }
    }
}

impl Model<MockTypeConfig> for MockModel {
    type Error = MockError;
    type Store = MockStore;

    fn belongs_to(&self) -> Option<Vec<MockObjectId>> {
        self.parent_ids.clone()
    }

    fn object_id(&self) -> MockObjectId {
        self.id.clone()
    }

    async fn execute(
        self,
        store: &Self::Store,
    ) -> Result<Vec<ExecuteReference<MockTypeConfig>>, <Self::Store as Store<MockTypeConfig>>::Error>
    {
        store.save(self).await
    }

    fn transition(&mut self, model: &Self) -> Result<bool, Self::Error> {
        // Simulate transition logic: if the incoming model has a higher value, transition occurs
        if model.value > self.value {
            self.value = model.value;
            self.transition_count += 1;
            Ok(true)
        } else {
            Ok(false)
        }
    }
}

// Mock error type
#[derive(Debug, thiserror::Error, PartialEq, Eq)]
pub enum MockError {
    #[error("Model not found: {0}")]
    NotFound(String),
}

// Mock store for testing
#[derive(Debug, Clone)]
pub struct MockStore {
    pub models: Arc<RwLock<HashMap<MockObjectId, MockModel>>>,
}

impl Default for MockStore {
    fn default() -> Self {
        Self::new()
    }
}

impl MockStore {
    pub fn new() -> Self {
        Self {
            models: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    pub async fn insert(&self, model: MockModel) {
        let mut models = self.models.write().await;
        models.insert(model.object_id(), model);
    }

    pub async fn get_model(&self, id: &MockObjectId) -> Option<MockModel> {
        let models = self.models.read().await;
        models.get(id).cloned()
    }
}

impl Store<MockTypeConfig> for MockStore {
    type Model = MockModel;
    type Error = MockError;

    async fn get(&self, id: &MockObjectId) -> Result<Self::Model, Self::Error> {
        self.get_model(id)
            .await
            .ok_or_else(|| MockError::NotFound(id.0.clone()))
    }

    async fn save(
        &self,
        model: Self::Model,
    ) -> Result<Vec<ExecuteReference<MockTypeConfig>>, Self::Error> {
        self.insert(model.clone()).await;
        Ok(vec![ExecuteReference::Model(model.object_id())])
    }

    async fn save_many<I: Iterator<Item = Self::Model> + Send>(
        &self,
        models: I,
    ) -> Result<Vec<ExecuteReference<MockTypeConfig>>, Self::Error> {
        let mut references = Vec::new();
        for model in models {
            self.insert(model.clone()).await;
            references.push(ExecuteReference::Model(model.object_id()));
        }
        Ok(references)
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[tokio::test]
    async fn test_mock_implementations() {
        let room_id = MockRoomId("!room1:example.com".to_string());
        let object_id = MockObjectId("obj1".to_string());
        let model_type = MockModelType("model1".to_string());
        let account_data = "account1".to_string();
        let user_id = "user1".to_string();
        let timestamp = "2021-01-01T00:00:00Z".to_string();

        assert_eq!(room_id.as_ref(), "!room1:example.com");
        assert_eq!(object_id.as_ref(), "obj1");
        assert_eq!(model_type.as_ref(), "model1");
        assert_eq!(account_data, "account1");
        assert_eq!(user_id, "user1");
        assert_eq!(timestamp, "2021-01-01T00:00:00Z");

        let store = MockStore::new();

        let model = MockModel::new("obj1", 10, None);
        assert_eq!(model.object_id(), object_id);
        assert_eq!(model.value, 10);
        assert_eq!(model.parent_ids, None);
        assert_eq!(model.transition_count, 0);
        model.execute(&store).await.unwrap();
    }
}
