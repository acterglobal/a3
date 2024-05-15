use matrix_sdk::Client;
use ruma::OwnedRoomId;
use ruma_common::{OwnedUserId, UserId};
use scc::hash_map::{Entry, HashMap};
use std::collections::HashSet as StdHashSet;
use std::sync::{Arc, Mutex as StdMutex};
use tracing::{debug, error, info, instrument, trace, warn};

use crate::{
    models::{ActerModel, AnyActerModel},
    Error, Result,
};

#[derive(Clone, Debug)]
pub struct Store {
    pub(crate) client: Client,
    user_id: OwnedUserId,
    models: Arc<HashMap<String, AnyActerModel>>,
    indizes: Arc<HashMap<String, Vec<String>>>,
    dirty: Arc<StdMutex<StdHashSet<String>>>, // our key mutex;
}

static ALL_MODELS_KEY: &str = "ACTER::ALL";
static DB_VERSION_KEY: &str = "ACTER::DB_VERSION";
static CURRENT_DB_VERSION: u32 = 1;

type ModelKeysAndIndizes = (Vec<String>, Vec<String>);

async fn get_from_store<T: serde::de::DeserializeOwned>(client: Client, key: &str) -> Result<T> {
    let v = client
        .store()
        .get_custom_value(format!("acter:{key}").as_bytes())
        .await?
        .ok_or_else(|| Error::ModelNotFound(key.to_owned()))?;
    Ok(serde_json::from_slice(v.as_slice())?)
}

impl Store {
    pub async fn get_raw<T: serde::de::DeserializeOwned>(&self, key: &str) -> Result<T> {
        get_from_store(self.client.clone(), key).await
    }

    pub fn user_id(&self) -> &UserId {
        &self.user_id
    }

    pub async fn set_raw<T: serde::Serialize>(&self, key: &str, value: &T) -> Result<()> {
        trace!(key, "set_raw");
        self.client
            .store()
            .set_custom_value_no_read(
                format!("acter:{key}").as_bytes(),
                serde_json::to_vec(value)?,
            )
            .await?;
        Ok(())
    }

    pub async fn new(client: Client) -> Result<Self> {
        let user_id = client.user_id().ok_or(Error::ClientNotLoggedIn)?.to_owned();
        Self::new_inner(client, user_id).await
    }

    #[cfg(test)]
    pub(crate) async fn new_with_auth(client: Client, user_id: OwnedUserId) -> Result<Self> {
        Self::new_inner(client, user_id).await
    }

    async fn new_inner(client: Client, user_id: OwnedUserId) -> Result<Self> {
        let ver = client
            .store()
            .get_custom_value(DB_VERSION_KEY.as_bytes())
            .await
            .map_err(|e| Error::Custom(format!("failed to find DB version key: {e}")))?
            .map(|u| u32::from_le_bytes(u.as_chunks().0[0]))
            .unwrap_or_default();
        if ver < CURRENT_DB_VERSION {
            // "upgrading" by resetting
            client
                .store()
                .set_custom_value_no_read(ALL_MODELS_KEY.as_bytes(), vec![])
                .await
                .map_err(|e| Error::Custom(format!("setting all models to [] failed: {e}")))?;

            client
                .store()
                .set_custom_value_no_read(
                    DB_VERSION_KEY.as_bytes(),
                    CURRENT_DB_VERSION.to_le_bytes().to_vec(),
                )
                .await
                .map_err(|e| Error::Custom(format!("setting db version failed: {e}")))?;

            return Ok(Store {
                client,
                user_id,
                indizes: Default::default(),
                models: Default::default(),
                dirty: Default::default(),
            });
        }

        // current DB version, attempt to load models

        let data = client
            .store()
            .get_custom_value(ALL_MODELS_KEY.as_bytes())
            .await?
            .map(|v| {
                if v.is_empty() {
                    Ok(vec![])
                } else {
                    serde_json::from_slice::<Vec<String>>(&v)
                }
            })
            .transpose()
            .map_err(|e| Error::Custom(format!("deserializing all models index failed: {e}")))?;
        let models_vec = if let Some(v) = data {
            let items = v.iter().map(|k| {
                let client = client.clone();
                async move {
                    match get_from_store::<AnyActerModel>(client, k).await {
                        Ok(m) => Some(m),
                        Err(e) => {
                            tracing::error!("Couldn't read model at startup. Skipping. {e}");
                            None
                        }
                    }
                }
            });
            futures::future::join_all(items).await
        } else {
            vec![]
        };

        let indizes: HashMap<String, Vec<String>> = HashMap::new();
        let models: HashMap<String, AnyActerModel> = HashMap::new();
        for m in models_vec {
            let Some(m) = m else {
                // skip None's
                continue;
            };
            let key = m.event_id().to_string();
            for idx in m.indizes(&user_id) {
                match indizes.entry(idx) {
                    Entry::Occupied(mut o) => {
                        o.get_mut().push(key.clone());
                    }
                    Entry::Vacant(v) => {
                        v.insert_entry(vec![key.clone()]);
                    }
                };
            }
            // ignore duplicates
            let _ = models.insert(key, m);
        }

        Ok(Store {
            client,
            user_id,
            indizes: Arc::new(indizes),
            models: Arc::new(models),
            dirty: Default::default(),
        })
    }

    #[instrument(skip(self))]
    pub async fn get_list(&self, key: &str) -> Result<impl Iterator<Item = AnyActerModel>> {
        self.get_list_inner(key)
    }

    pub fn get_list_inner(&self, key: &str) -> Result<impl Iterator<Item = AnyActerModel>> {
        let listing = if let Some(r) = self.indizes.get(key) {
            r.get().clone()
        } else {
            debug!(user=?self.user_id, key, "No list found");
            vec![]
        };
        let models = self.models.clone();
        let res = listing
            .into_iter()
            .filter_map(move |name| models.get(&name).map(|v| v.get().clone()));
        Ok(res)
    }

    pub async fn get(&self, model_key: &str) -> Result<AnyActerModel> {
        let Some(o) = self.models.get_async(model_key).await else {
            return Err(Error::ModelNotFound(model_key.to_owned()));
        };

        Ok(o.get().clone())
    }

    pub async fn get_many(&self, model_keys: Vec<String>) -> Vec<Option<AnyActerModel>> {
        let models = model_keys.iter().map(|k| async { self.get(k).await.ok() });
        futures::future::join_all(models).await
    }

    #[instrument(skip(self))]
    async fn save_model_inner(&self, mdl: AnyActerModel) -> Result<Vec<String>> {
        let mut dirty = self.dirty.lock()?; // hold the lock
        let (mut keys, indizes) = self.model_inner_under_lock(mdl)?;
        dirty.extend(keys.clone());
        keys.extend(indizes);
        Ok(keys)
    }

    fn model_inner_under_lock(&self, mdl: AnyActerModel) -> Result<ModelKeysAndIndizes> {
        let key = mdl.event_id().to_string();
        let user_id = self.user_id();
        let room_id_idx = format!("{}::models", mdl.room_id());
        let mut keys_changed = vec![key.clone()];
        trace!(user = ?user_id, key, "saving");
        let mut indizes = mdl.indizes(user_id);
        match self.models.entry(key.clone()) {
            Entry::Vacant(v) => {
                v.insert_entry(mdl);
            }
            Entry::Occupied(mut o) => {
                trace!(user=?self.user_id, key, "previous model found");
                let prev = o.insert(mdl);

                let mut remove_idzs = Vec::new();
                for idz in prev.indizes(user_id) {
                    if let Some(idx) = indizes.iter().position(|i| i == &idz) {
                        indizes.remove(idx);
                    } else {
                        remove_idzs.push(idz)
                    }
                }

                for idz in remove_idzs {
                    if let Some(mut v) = self.indizes.get(&idz) {
                        v.get_mut().retain(|k| k != &key);
                    }
                    keys_changed.push(idz);
                }
            }
        }

        for idx in indizes.iter().chain([&room_id_idx]) {
            trace!(user = ?self.user_id, idx, key, exists=self.indizes.contains(idx), "adding to index");
            match self.indizes.entry(idx.clone()) {
                Entry::Vacant(v) => {
                    v.insert_entry(vec![key.clone()]);
                }
                Entry::Occupied(mut o) => {
                    o.get_mut().push(key.clone());
                }
            }
            trace!(user = ?self.user_id, idx, key, "added to index");
        }
        trace!(user=?self.user_id, key, ?keys_changed, "saved");
        Ok((keys_changed, indizes))
    }

    pub async fn save_many(&self, models: Vec<AnyActerModel>) -> Result<Vec<String>> {
        let mut total_keys = Vec::new();
        let mut total_indizes = Vec::new();
        {
            let mut dirty = self.dirty.lock()?; // hold the lock
            for mdl in models.into_iter() {
                let (keys, indizes) = self.model_inner_under_lock(mdl)?;
                dirty.extend(keys.clone());
                total_keys.extend(keys);
                total_indizes.extend(indizes);
            }
        }
        self.sync().await?; // FIXME: should we really run this every time?

        // clean out the duplicates
        total_keys.sort();
        total_keys.dedup();
        total_indizes.sort();
        total_indizes.dedup();

        Ok(total_keys
            .into_iter()
            .chain(total_indizes.into_iter())
            .collect())
    }

    pub async fn save(&self, mdl: AnyActerModel) -> Result<Vec<String>> {
        let keys = self.save_model_inner(mdl).await?;
        self.sync().await?; // FIXME: should we really run this every time?
        Ok(keys)
    }

    pub async fn clear_room(&self, room_id: &OwnedRoomId) -> Result<Vec<String>> {
        info!(?room_id, "clearing room");
        let idx = format!("{room_id}::models");
        let mut total_changed = {
            let mut dirty = self.dirty.lock()?; // hold the lock
            let mut total_changed = Vec::new();
            for model in self.get_list_inner(&idx)? {
                let model_id = model.event_id().to_string();
                let indizes = model.indizes(&self.user_id);
                // remove it from all indizes
                for index in indizes {
                    let _ = self
                        .indizes
                        .entry(index.clone())
                        .and_modify(|l| l.retain(|o| *o != model_id));
                    total_changed.push(index);
                }
                // remove the model itself
                self.models.remove(&model_id);
                dirty.insert(model_id.clone());
                total_changed.push(model_id);
            }

            // remove the room-id based index
            self.indizes.remove(&idx);
            total_changed
        };
        self.sync().await?;

        total_changed.sort();
        total_changed.dedup();

        Ok(total_changed)
    }

    async fn sync(&self) -> Result<()> {
        trace!("sync start");
        let (models_to_write, to_remove, all_models) = {
            trace!("preparing models");
            // preparing for sync
            let mut dirty = self.dirty.lock()?;
            let mut to_remove = Vec::new();
            let mut models_to_write = Vec::new();
            for key in dirty.iter() {
                let Some(r) = self.models.get(key) else {
                    info!(?key, "Model missing, removing custom value");
                    to_remove.push(format!("acter:{key}"));
                    continue;
                };
                let raw = match serde_json::to_vec(r.get()) {
                    Ok(r) => r,
                    Err(error) => {
                        error!(?key, ?error, "failed to serialize. remove");
                        continue;
                    }
                };
                models_to_write.push((format!("acter:{key}"), raw))
            }

            let model_keys: Vec<String> = {
                let mut model_keys: StdHashSet<String> = StdHashSet::new();
                // deduplicate the model_keys;
                self.models.scan(|k, _v| {
                    model_keys.insert(k.clone());
                });
                model_keys.into_iter().collect()
            };

            dirty.clear(); // we clear the current set
            trace!("preparation done");
            (models_to_write, to_remove, serde_json::to_vec(&model_keys)?)
        };
        trace!("store sync");
        let client_store = self.client.store();
        for (key, value) in models_to_write.into_iter() {
            if let Err(error) = client_store
                .set_custom_value_no_read(key.as_bytes(), value)
                .await
            {
                error!(?key, ?error, "syncing model failed");
            }
        }
        trace!("done store syncing");

        trace!("syncing all models");
        client_store
            .set_custom_value_no_read(ALL_MODELS_KEY.as_bytes(), all_models)
            .await?;

        trace!("removing old models");
        for key in to_remove.into_iter() {
            if let Err(error) = client_store.remove_custom_value(key.as_bytes()).await {
                warn!(key, ?error, "Error removing model");
            }
        }

        trace!("sync done");

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::{TestModel, TestModelBuilder};
    use anyhow::bail;
    use matrix_sdk_base::store::{MemoryStore, StoreConfig};
    use ruma::{event_id, OwnedEventId, OwnedRoomId};
    use ruma_common::{api::MatrixVersion, user_id};

    async fn fresh_store_and_client() -> Result<(Store, Client)> {
        let config = StoreConfig::default().state_store(MemoryStore::new());
        let client = Client::builder()
            .homeserver_url("http://localhost")
            .server_versions([MatrixVersion::V1_5])
            .store_config(config)
            .build()
            .await
            .unwrap();

        Ok((
            Store::new_with_auth(client.clone(), user_id!("@test:example.org").to_owned()).await?,
            client,
        ))
    }
    async fn fresh_store() -> Result<Store> {
        Ok(fresh_store_and_client().await?.0)
    }

    #[tokio::test]
    async fn smoke_test() -> Result<()> {
        let _ = env_logger::try_init();
        let _ = fresh_store().await?;
        Ok(())
    }

    #[tokio::test]
    async fn save_and_get_one_simple() -> anyhow::Result<()> {
        let _ = env_logger::try_init();
        let store = fresh_store().await?;
        let model = TestModelBuilder::default().simple().build().unwrap();
        let key = model.event_id().to_string();
        let res_keys = store.save(AnyActerModel::TestModel(model.clone())).await?;
        assert_eq!(vec![key.clone()], res_keys);
        let mdl = store.get(&key).await?;
        let AnyActerModel::TestModel(other) = mdl else {
            bail!("Returned model isn't test model: {mdl:?}");
        };
        assert_eq!(model, other);
        Ok(())
    }

    #[tokio::test]
    async fn save_and_get_many_simple() -> anyhow::Result<()> {
        let _ = env_logger::try_init();
        let store = fresh_store().await?;
        let models: Vec<TestModel> = (0..5)
            .map(|idx| {
                TestModelBuilder::default()
                    .simple()
                    .event_id(OwnedEventId::try_from(format!("$ASDF{idx}")).unwrap())
                    .build()
                    .unwrap()
            })
            .collect();
        let res_keys = store
            .save_many(
                models
                    .iter()
                    .map(|m| AnyActerModel::TestModel(m.clone()))
                    .collect(),
            )
            .await?;
        assert_eq!(
            models
                .iter()
                .map(|m| m.event_id().to_string())
                .collect::<Vec<String>>(),
            res_keys
        );

        let loaded_models = store
            .get_many(
                models
                    .iter()
                    .map(|m| m.event_id().to_string())
                    .collect::<Vec<String>>(),
            )
            .await
            .into_iter()
            .filter_map(|m| match m {
                Some(AnyActerModel::TestModel(inner)) => Some(inner),
                _ => None,
            })
            .collect::<Vec<_>>();
        assert_eq!(models, loaded_models);

        for model in models.into_iter() {
            let key = model.event_id().to_string();
            let mdl = store.get(&key).await?;
            let AnyActerModel::TestModel(other) = mdl else {
                bail!("Returned model isn't test model: {mdl:?}");
            };
            assert_eq!(model, other);
        }
        Ok(())
    }

    #[tokio::test]
    async fn save_and_get_one_from_index() -> anyhow::Result<()> {
        let _ = env_logger::try_init();
        let store = fresh_store().await?;
        let model = TestModelBuilder::default()
            .simple()
            .indizes(vec!["indexA".to_owned(), "index::b".to_owned()])
            .build()
            .unwrap();
        let key = model.event_id().to_string();
        let res_keys = store.save(AnyActerModel::TestModel(model.clone())).await?;
        assert_eq!(
            vec![key.clone(), "indexA".to_owned(), "index::b".to_owned()],
            res_keys
        );
        let mdl = store.get(&key).await?;
        let AnyActerModel::TestModel(other) = mdl else {
            bail!("Returned model isn't test model: {mdl:?}");
        };
        assert_eq!(model, other);

        let mut index = store.get_list("indexA").await?;
        let Some(AnyActerModel::TestModel(other)) = index.next() else {
            bail!("Returned model isn't test model.");
        };
        assert!(index.next().is_none()); // and nothing else
        assert_eq!(model, other);

        let mut index = store.get_list("index::b").await?;
        let Some(AnyActerModel::TestModel(other)) = index.next() else {
            bail!("Returned model isn't test model.");
        };
        assert!(index.next().is_none()); // and nothing else
        assert_eq!(model, other);

        let mut index = store.get_list("empty_index").await?;
        assert!(index.next().is_none()); // and nothing here
        assert_eq!(model, other);

        Ok(())
    }

    #[tokio::test]
    async fn add_get_one_to_index() -> anyhow::Result<()> {
        let _ = env_logger::try_init();
        let store = fresh_store().await?;
        let model = TestModelBuilder::default()
            .simple()
            .indizes(vec!["indexA".to_owned()])
            .build()
            .unwrap();
        let key = model.event_id().to_string();
        let res_keys = store.save(AnyActerModel::TestModel(model.clone())).await?;
        assert_eq!(vec![key.clone(), "indexA".to_owned()], res_keys);

        let mut index = store.get_list("indexA").await?;
        let Some(AnyActerModel::TestModel(other)) = index.next() else {
            bail!("Returned model isn't test model.");
        };
        assert!(index.next().is_none()); // and nothing else
        assert_eq!(model, other);

        let second_model = TestModelBuilder::default()
            .simple()
            .event_id(OwnedEventId::try_from("$secondModel").unwrap())
            .indizes(vec!["indexA".to_owned()])
            .build()
            .unwrap();
        let key = second_model.event_id().to_string();
        let res_keys = store
            .save(AnyActerModel::TestModel(second_model.clone()))
            .await?;
        assert_eq!(vec![key.clone(), "indexA".to_owned()], res_keys);

        let mut index = store.get_list("indexA").await?;
        let Some(AnyActerModel::TestModel(other)) = index.next() else {
            bail!("Returned model isn't test model.");
        };
        assert_eq!(model, other);

        let Some(AnyActerModel::TestModel(other)) = index.next() else {
            bail!("Returned model isn't test model.");
        };
        assert_eq!(second_model, other);

        assert!(index.next().is_none()); // and nothing else

        Ok(())
    }

    #[tokio::test]
    async fn model_changed_index() -> anyhow::Result<()> {
        let _ = env_logger::try_init();
        let e_id = event_id!("$asdfAsdf");
        let store = fresh_store().await?;
        {
            let model = TestModelBuilder::default()
                .simple()
                .event_id(e_id.to_owned())
                .indizes(vec!["indexA".to_owned(), "index::b".to_owned()])
                .build()
                .unwrap();
            let key = model.event_id().to_string();
            let res_keys = store.save(AnyActerModel::TestModel(model.clone())).await?;
            assert_eq!(
                vec![key.clone(), "indexA".to_owned(), "index::b".to_owned()],
                res_keys
            );
            let mdl = store.get(&key).await?;
            let AnyActerModel::TestModel(other) = mdl else {
                bail!("Returned model isn't test model: {mdl:?}");
            };
            assert_eq!(model, other);

            let mut index = store.get_list("indexA").await?;
            let Some(AnyActerModel::TestModel(other)) = index.next() else {
                bail!("Returned model isn't test model.");
            };
            assert!(index.next().is_none()); // and nothing else
            assert_eq!(model, other);

            let mut index = store.get_list("index::b").await?;
            let Some(AnyActerModel::TestModel(other)) = index.next() else {
                bail!("Returned model isn't test model.");
            };
            assert!(index.next().is_none()); // and nothing else
            assert_eq!(model, other);

            let mut index = store.get_list("new_index").await?;
            assert!(index.next().is_none()); // and nothing here
            assert_eq!(model, other);
        }
        {
            // overwriting the indexes with a new set
            let model = TestModelBuilder::default()
                .simple()
                .event_id(e_id.to_owned())
                .indizes(vec!["new_index".to_owned()])
                .build()
                .unwrap();
            let key = model.event_id().to_string();
            // we overwrite this
            let res_keys = store.save(AnyActerModel::TestModel(model.clone())).await?;
            assert_eq!(
                vec![
                    key.clone(),
                    "indexA".to_owned(),
                    "index::b".to_owned(),
                    "new_index".to_owned()
                ],
                res_keys
            );
            let mut index = store.get_list("indexA").await?;
            assert!(index.next().is_none()); // empty now

            let mut index = store.get_list("index::b").await?;
            assert!(index.next().is_none()); // empty now

            // only via our new index
            let mut index = store.get_list("new_index").await?;
            let Some(AnyActerModel::TestModel(other)) = index.next() else {
                bail!("Returned model isn't test model.");
            };
            assert!(index.next().is_none()); // and nothing else
            assert_eq!(model, other);
        }

        Ok(())
    }

    #[tokio::test]
    async fn recover() -> anyhow::Result<()> {
        let _ = env_logger::try_init();
        let (client, model) = {
            let (store, client) = fresh_store_and_client().await?;
            let model = TestModelBuilder::default()
                .simple()
                .indizes(vec!["test_index".to_owned()])
                .build()
                .unwrap();
            let key = model.event_id().to_string();
            let res_keys = store.save(AnyActerModel::TestModel(model.clone())).await?;
            assert_eq!(vec![key.clone(), "test_index".to_owned()], res_keys);
            let mdl = store.get(&key).await?;
            let AnyActerModel::TestModel(other) = mdl else {
                bail!("Returned model isn't test model: {mdl:?}");
            };
            assert_eq!(model, other);
            (client, model)
        };

        // let's attempt to recover
        let store =
            Store::new_with_auth(client.clone(), user_id!("@test:example.org").to_owned()).await?;

        // and we should be able to get it again.
        let mdl = store.get(model.event_id().as_ref()).await?;
        let AnyActerModel::TestModel(other) = mdl else {
            bail!("Returned model isn't test model: {mdl:?}");
        };
        assert_eq!(model, other);

        // now recover from the the index!

        let mut index = store.get_list("test_index").await?;
        let Some(AnyActerModel::TestModel(other)) = index.next() else {
            bail!("Returned model isn't test model.");
        };
        assert!(index.next().is_none()); // and nothing else
        assert_eq!(model, other);

        let mut index = store.get_list("empty_index").await?;
        assert!(index.next().is_none()); // and nothing here
        assert_eq!(model, other);

        Ok(())
    }

    #[tokio::test]
    async fn save_and_get_raw_simple() -> anyhow::Result<()> {
        let _ = env_logger::try_init();
        let store = fresh_store().await?;
        let model = vec!["Just a simple string".to_owned()];
        let key = "random key we use";
        store.set_raw(key, &model).await?;
        let other: Vec<String> = store.get_raw(key).await?;
        assert_eq!(model, other);
        Ok(())
    }

    #[tokio::test]
    async fn remove_room() -> anyhow::Result<()> {
        let _ = env_logger::try_init();
        let store = fresh_store().await?;
        let first_room_id = OwnedRoomId::try_from("!firstRoom:example.org").unwrap();
        let second_room_id = OwnedRoomId::try_from("!secondRoom:example.org").unwrap();
        let index_a = "index_a".to_owned();
        let index_b = "index_b".to_owned();
        let index_c = "index_c".to_owned();

        let first_room_models = (0..5)
            .map(|idx| {
                TestModelBuilder::default()
                    .simple()
                    .event_id(OwnedEventId::try_from(format!("$ASDF{idx}")).unwrap())
                    .indizes(vec![index_a.clone(), index_c.clone()])
                    .room_id(first_room_id.clone())
                    .build()
                    .unwrap()
            })
            .collect::<Vec<_>>();

        let second_room_models = (0..5)
            .map(|idx| {
                TestModelBuilder::default()
                    .simple()
                    .event_id(OwnedEventId::try_from(format!("$IDX{idx}")).unwrap())
                    .indizes(vec![index_a.clone(), index_b.clone()])
                    .room_id(second_room_id.clone())
                    .build()
                    .unwrap()
            })
            .collect::<Vec<_>>();

        let first_model_keys = first_room_models
            .iter()
            .map(|m| m.event_id().to_string())
            .collect::<Vec<String>>();
        let second_model_keys = second_room_models
            .iter()
            .map(|m| m.event_id().to_string())
            .collect::<Vec<String>>();

        let all_model_keys = first_model_keys
            .iter()
            .chain(second_model_keys.iter())
            .map(Clone::clone)
            .collect::<Vec<String>>();

        // submit all
        let res_keys = store
            .save_many(
                first_room_models
                    .iter()
                    .chain(second_room_models.iter())
                    .map(|m| AnyActerModel::TestModel(m.clone()))
                    .collect(),
            )
            .await?;

        // confirm all is in order:
        assert_eq!(
            all_model_keys
                .into_iter()
                .chain(
                    // add the indizes that are also updated
                    ["index_a", "index_b", "index_c"]
                        .into_iter()
                        .map(ToString::to_string)
                )
                .collect::<Vec<String>>(),
            res_keys
        );

        let loaded_models_first = store
            .get_many(first_model_keys.clone())
            .await
            .into_iter()
            .filter_map(|m| match m {
                Some(AnyActerModel::TestModel(inner)) => Some(inner),
                _ => None,
            })
            .collect::<Vec<_>>();
        assert_eq!(first_room_models, loaded_models_first);

        let loaded_models_second = store
            .get_many(second_model_keys.clone())
            .await
            .into_iter()
            .filter_map(|m| match m {
                Some(AnyActerModel::TestModel(inner)) => Some(inner),
                _ => None,
            })
            .collect::<Vec<_>>();
        assert_eq!(second_room_models, loaded_models_second);

        //  --- now let's remove the first room ---
        let notifiers = store.clear_room(&first_room_id).await?;
        assert_eq!(notifiers.len(), 7); // 5 models & 2 indizes = 7 changes

        // first room models are all gone:
        for new in store.get_many(first_model_keys.clone()).await {
            assert!(new.is_none(), "first model still found {new:?}");
        }

        // but second are all there

        let loaded_models_second = store
            .get_many(second_model_keys.clone())
            .await
            .into_iter()
            .filter_map(|m| match m {
                Some(AnyActerModel::TestModel(inner)) => Some(inner),
                _ => None,
            })
            .collect::<Vec<_>>();
        assert_eq!(second_room_models, loaded_models_second);

        Ok(())
    }
}
