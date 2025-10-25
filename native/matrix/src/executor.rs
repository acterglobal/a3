use crate::{config::MatrixCoreTypeConfig, store::Store};

pub type Executor = acter_core::executor::Executor<MatrixCoreTypeConfig, Store>;

#[cfg(test)]
mod tests {
    use std::borrow::Cow;

    use super::*;
    use crate::{
        events::{comments::CommentEventContent, BelongsTo},
        models::{ActerModel, AnyActerModel, Comment, TestModelBuilder},
        referencing::{IndexKey, IntoExecuteReference, ObjectListIndex},
        store::Store,
    };
    use anyhow::Result;
    use matrix_sdk::Client;
    use matrix_sdk_base::{
        ruma::{
            api::MatrixVersion, event_id, events::room::message::TextMessageEventContent, user_id,
        },
        store::{MemoryStore, StoreConfig},
    };

    async fn fresh_executor() -> Result<Executor> {
        let config = StoreConfig::new("tests".to_owned()).state_store(MemoryStore::new());
        let client = Client::builder()
            .homeserver_url("http://localhost")
            .server_versions([MatrixVersion::V1_5])
            .store_config(config)
            .build()
            .await
            .unwrap();

        let store = Store::new_with_auth(client, user_id!("@test:example.org").to_owned()).await?;
        Ok(Executor::new(store))
    }

    #[tokio::test]
    async fn smoke_test() -> Result<()> {
        let _ = env_logger::try_init();
        let _ = fresh_executor().await?;
        Ok(())
    }

    #[tokio::test]
    async fn subscribe_simple_model() -> Result<()> {
        let _ = env_logger::try_init();
        let executor = fresh_executor().await?;
        let model = TestModelBuilder::default().simple().build().unwrap();
        let model_id = model.event_id();
        let sub = executor.subscribe(IntoExecuteReference::into(model_id));
        assert!(sub.is_empty(), "Already received an event");

        executor.handle(model.into()).await?;
        assert!(!sub.is_empty(), "No subscription event found");

        Ok(())
    }

    #[tokio::test]
    async fn subscribe_referenced_model() -> Result<()> {
        let _ = env_logger::try_init();
        let executor = fresh_executor().await?;
        let model = TestModelBuilder::default().simple().build().unwrap();
        let model_id = model.event_id().to_owned();
        let mut sub = executor.subscribe(IntoExecuteReference::into(model_id.clone()));
        assert!(sub.is_empty());

        executor.handle(model.into()).await?;
        assert!(sub.recv().await.is_ok()); // we have one
        assert!(sub.is_empty());

        let child = TestModelBuilder::default()
            .simple()
            .belongs_to(vec![model_id.clone()])
            .event_id(event_id!("$advf93m").to_owned())
            .build()
            .unwrap();

        executor.handle(child.into()).await?;

        assert!(sub.recv().await.is_ok()); // we have one
        assert!(sub.is_empty());
        Ok(())
    }

    #[tokio::test]
    async fn subscribe_models_index() -> Result<()> {
        let _ = env_logger::try_init();
        let executor = fresh_executor().await?;
        let model = TestModelBuilder::default().simple().build().unwrap();
        let parent_id = model.event_id().to_owned();
        let parent_idx = IndexKey::ObjectList(parent_id.clone(), ObjectListIndex::Attachments);
        let mut sub = executor.subscribe(IntoExecuteReference::into(parent_idx.clone()));
        assert!(sub.is_empty());

        executor.handle(model.into()).await?;
        assert!(sub.is_empty());

        let child = TestModelBuilder::default()
            .simple()
            .belongs_to(vec![parent_id.clone()])
            .event_id(event_id!("$advf93m").to_owned())
            .indizes(vec![parent_idx.clone()])
            .build()
            .unwrap();

        executor.handle(child.into()).await?;

        assert!(sub.recv().await.is_ok()); // we have one
        assert!(sub.is_empty());
        Ok(())
    }

    #[tokio::test]
    async fn subscribe_models_comments_index() -> Result<()> {
        let _ = env_logger::try_init();
        let executor = fresh_executor().await?;
        let model = TestModelBuilder::default().simple().build().unwrap();
        let parent_id = model.event_id().to_owned();
        let parent_idx = Comment::index_for(parent_id.clone());
        let mut sub = executor.subscribe(IntoExecuteReference::into(parent_idx.clone()));
        assert!(sub.is_empty());

        executor.handle(model.into()).await?;
        assert!(sub.is_empty());

        let comment = Comment {
            inner: CommentEventContent {
                content: TextMessageEventContent::plain("First"),
                on: BelongsTo {
                    event_id: parent_id,
                },
                reply_to: None,
            },
            meta: TestModelBuilder::fake_meta(),
        };

        executor.handle(comment.into()).await?;

        assert!(sub.recv().await.is_ok()); // we have one
        assert!(sub.is_empty());
        Ok(())
    }

    #[tokio::test]
    async fn wait_for_simple_model() -> Result<()> {
        let _ = env_logger::try_init();
        let executor = fresh_executor().await?;
        let model = TestModelBuilder::default().simple().build().unwrap();
        let model_id = model.event_id().to_owned();
        // nothing in the store
        assert!(executor.store().get(&model_id).await.is_err());

        let waiter = executor.wait_for(model_id);
        executor.handle(model.clone().into()).await?;

        let new_model = waiter.await?;

        let AnyActerModel::TestModel(inner_model) = new_model else {
            panic!("Not a test model");
        };

        assert_eq!(inner_model, model);
        Ok(())
    }

    #[tokio::test]
    async fn double_redact_model() -> Result<()> {
        let _ = env_logger::try_init();
        let executor = fresh_executor().await?;
        let model = TestModelBuilder::default().simple().build().unwrap();
        let model_id = model.event_id().to_owned();
        // nothing in the store
        assert!(executor.store().get(&model_id).await.is_err());

        let waiter = executor.wait_for(model_id.clone());
        executor.handle(model.clone().into()).await?;

        let new_model = waiter.await?;

        let AnyActerModel::TestModel(inner_model) = new_model else {
            panic!("Not a test model");
        };

        assert_eq!(inner_model, model);

        // now let’s redact this model;

        executor
            .redact(
                Cow::Owned("test_model".to_owned()),
                model.event_meta().clone(),
                None,
            )
            .await?;

        let AnyActerModel::RedactedActerModel(redaction) = executor.store().get(&model_id).await?
        else {
            panic!("Model was not redacten :(");
        };
        assert_eq!(redaction.origin_type(), "test_model");

        // redacting again

        executor
            .redact(
                Cow::Owned("test_model".to_owned()),
                model.event_meta().clone(),
                None,
            )
            .await?;

        let AnyActerModel::RedactedActerModel(redaction) = executor.store().get(&model_id).await?
        else {
            panic!("Model was not redacted :(");
        };
        assert_eq!(redaction.origin_type(), "test_model"); // we stay with the existing redaction

        Ok(())
    }
}
