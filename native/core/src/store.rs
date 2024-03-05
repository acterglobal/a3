use matrix_sdk::Client;
use ruma_common::{OwnedUserId, UserId};
use scc::hash_map::{Entry, HashMap};
use std::collections::HashSet as StdHashSet;
use std::sync::{Arc, Mutex as StdMutex};
use tracing::{debug, error, instrument, trace, warn};

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
            .set_custom_value(
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
                .set_custom_value(ALL_MODELS_KEY.as_bytes(), vec![])
                .await
                .map_err(|e| Error::Custom(format!("setting all models to [] failed: {e}")))?;

            client
                .store()
                .set_custom_value(
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
        let keys = self.model_inner_under_lock(mdl)?;
        dirty.extend(keys.clone());
        Ok(keys)
    }

    fn model_inner_under_lock(&self, mdl: AnyActerModel) -> Result<Vec<String>> {
        let key = mdl.event_id().to_string();
        let user_id = self.user_id();
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
                    self.indizes
                        .get(&idz)
                        .map(|mut v| v.get_mut().retain(|k| k != &key));
                    keys_changed.push(idz);
                }
            }
        }

        for idx in indizes.into_iter() {
            trace!(user = ?self.user_id, idx, key, exists=self.indizes.contains(&idx), "adding to index");
            match self.indizes.entry(idx.clone()) {
                Entry::Vacant(v) => {
                    v.insert_entry(vec![key.clone()]);
                }
                Entry::Occupied(mut o) => {
                    o.get_mut().push(key.clone());
                }
            }
            trace!(user = ?self.user_id, idx, key, "added to index");
            keys_changed.push(idx);
        }
        trace!(user=?self.user_id, key, ?keys_changed, "saved");
        Ok(keys_changed)
    }

    pub async fn save_many(&self, models: Vec<AnyActerModel>) -> Result<Vec<String>> {
        let mut total_list = Vec::new();
        {
            let mut dirty = self.dirty.lock()?; // hold the lock
            for mdl in models.into_iter() {
                total_list.extend(self.model_inner_under_lock(mdl)?);
            }
            dirty.extend(total_list.clone());
        }
        self.sync().await?; // FIXME: should we really run this every time?
        Ok(total_list)
    }

    pub async fn save(&self, mdl: AnyActerModel) -> Result<Vec<String>> {
        let keys = self.save_model_inner(mdl).await?;
        self.sync().await?; // FIXME: should we really run this every time?
        Ok(keys)
    }

    async fn sync(&self) -> Result<()> {
        trace!("sync start");
        let (models_to_write, all_models) = {
            trace!("preparing models");
            // preparing for sync
            let mut dirty = self.dirty.lock()?;
            let models_to_write: Vec<(String, Vec<u8>)> = dirty
                .iter()
                .filter_map(|key| {
                    if let Some(r) = self.models.get(key) {
                        let raw = match serde_json::to_vec(r.get()) {
                            Ok(r) => r,
                            Err(error) => {
                                error!(?key, ?error, "failed to serialize. skipping");
                                return None;
                            }
                        };
                        Some((format!("acter:{key}"), raw))
                    } else {
                        warn!(
                            ?key,
                            "Inconsistency error: key is missing from models. skipping"
                        );
                        None
                    }
                })
                .collect();

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
            (models_to_write, serde_json::to_vec(&model_keys)?)
        };
        trace!("store sync");
        let client_store = self.client.store();
        for (key, value) in models_to_write.into_iter() {
            if let Err(error) = client_store.set_custom_value(key.as_bytes(), value).await {
                error!(?key, ?error, "syncing model failed");
            }
        }
        trace!("done store syncing");

        trace!("syncing all models");
        client_store
            .set_custom_value(ALL_MODELS_KEY.as_bytes(), all_models)
            .await?;

        trace!("sync done");

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{models::TestModelBuilder, Result};
    use anyhow::bail;
    use env_logger;
    use matrix_sdk::Client;
    use matrix_sdk_base::store::{MemoryStore, StoreConfig};
    use ruma_common::{api::MatrixVersion, event_id, user_id};
    use ruma_events::room::message::TextMessageEventContent;

    async fn fresh_store() -> Result<Store> {
        let config = StoreConfig::default().state_store(MemoryStore::new());
        let client = Client::builder()
            .homeserver_url("http://localhost")
            .server_versions([MatrixVersion::V1_5])
            .store_config(config)
            .build()
            .await
            .unwrap();

        Ok(Store::new_with_auth(client, user_id!("@test:example.org").to_owned()).await?)
    }

    #[tokio::test]
    async fn smoke_test() -> Result<()> {
        let _ = env_logger::try_init();
        let _ = fresh_store().await?;
        Ok(())
    }

    #[tokio::test]
    async fn save_and_get_one() -> anyhow::Result<()> {
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
}
