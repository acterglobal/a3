use dashmap::{mapref::one::RefMut, DashMap, DashSet};
use matrix_sdk::Client;
use std::{iter::FromIterator, sync::Arc};
use tracing::{debug, instrument, trace, warn};

use crate::{
    models::{ActerModel, AnyActerModel},
    Error, Result,
};

#[derive(Clone, Debug)]
pub struct Store {
    client: Client,
    fresh: bool,
    models: Arc<DashMap<String, AnyActerModel>>,
    indizes: Arc<DashMap<String, Vec<String>>>,
    dirty: Arc<DashSet<String>>,
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
        if self.fresh {
            return Err(Error::ModelNotFound(key.to_owned()));
        }
        get_from_store(self.client.clone(), key).await
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
                fresh: true,
                client,
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

        let indizes = DashMap::new();
        let mut models_sources = Vec::new();
        for m in models_vec {
            let Some(m) = m else {
                // skip None's
                continue
            };
            let key = m.event_id().to_string();
            for idx in m.indizes() {
                let mut r: RefMut<String, Vec<String>> = indizes.entry(idx).or_default();
                r.value_mut().push(key.clone())
            }
            models_sources.push((key, m));
        }

        let models = DashMap::from_iter(models_sources);

        Ok(Store {
            fresh: false,
            client,
            indizes: Arc::new(indizes),
            models: Arc::new(models),
            dirty: Default::default(),
        })
    }

    #[instrument(skip(self))]
    pub async fn get_list(&self, key: &str) -> Result<impl Iterator<Item = AnyActerModel>> {
        let listing = if let Some(r) = self.indizes.get(key) {
            r.value().clone()
        } else {
            debug!(user=?self.client.user_id(), key, "No list found");
            vec![]
        };
        let models = self.models.clone();
        let res = listing
            .into_iter()
            .filter_map(move |name| models.get(&name).map(|v| v.value().clone()));
        Ok(res)
    }

    pub async fn get(&self, model_key: &str) -> Result<AnyActerModel> {
        let m = self
            .models
            .get(model_key)
            .ok_or_else(|| Error::ModelNotFound(model_key.to_owned()))?
            .value()
            .clone();
        Ok(m)
    }

    pub async fn get_many(&self, model_keys: Vec<String>) -> Vec<Option<AnyActerModel>> {
        let models = model_keys.iter().map(|k| async { self.get(k).await.ok() });
        futures::future::join_all(models).await
    }

    #[instrument(skip(self))]
    pub async fn save_model_inner(&self, mdl: AnyActerModel) -> Result<Vec<String>> {
        let key = mdl.event_id().to_string();
        let mut keys_changed = vec![key.clone()];
        trace!(user=?self.client.user_id(), key, "saving");
        let mut indizes = mdl.indizes();
        if let Some(prev) = self.models.insert(key.clone(), mdl) {
            trace!(user=?self.client.user_id(), key, "previous model found");
            let mut remove_idzs = Vec::new();
            for idz in prev.indizes() {
                if let Some(idx) = indizes.iter().position(|i| i == &idz) {
                    indizes.remove(idx);
                } else {
                    remove_idzs.push(idz)
                }
            }

            for idz in remove_idzs {
                if let Some(mut v) = self.indizes.get_mut(&idz) {
                    v.value_mut().retain(|k| k != &key)
                }
                keys_changed.push(idz);
            }
        }
        for idx in indizes.into_iter() {
            trace!(user = ?self.client.user_id(), idx, key, exists=self.indizes.contains_key(&idx), "adding to index");
            self.indizes
                .entry(idx.clone())
                .or_default()
                .value_mut()
                .push(key.clone());
            trace!(user = ?self.client.user_id(), idx, key, "added to index");
            keys_changed.push(idx);
        }
        trace!(user=?self.client.user_id(), key, ?keys_changed, "saved");
        self.dirty.insert(key);
        Ok(keys_changed)
    }

    pub async fn save_many(&self, models: Vec<AnyActerModel>) -> Result<Vec<String>> {
        let mut total_list = Vec::new();
        for mdl in models.into_iter() {
            total_list.extend(self.save_model_inner(mdl).await?);
        }
        self.sync().await?; // FIXME: should we really run this every time?
        Ok(total_list)
    }

    pub async fn save(&self, mdl: AnyActerModel) -> Result<Vec<String>> {
        let keys = self.save_model_inner(mdl).await?;
        self.sync().await?; // FIXME: should we really run this every time?
        Ok(keys)
    }

    pub async fn sync(&self) -> Result<()> {
        trace!("sync");
        let client_store = self.client.store();
        let dirty = {
            let keys = self
                .dirty
                .iter()
                .map(|k| k.key().to_owned())
                .collect::<Vec<String>>();
            self.dirty.clear(); // no lock, not good!
            keys
        };
        for key in dirty {
            if let Some(r) = self.models.get(&key) {
                trace!(?key, "syncing");
                // FIXME: parallize
                client_store
                    .set_custom_value(
                        format!("acter:{key}").as_bytes(),
                        serde_json::to_vec(r.value())?,
                    )
                    .await?;
            } else {
                warn!(key, "Inconsistency error: key is missing");
            }
        }

        trace!("syncing all models");
        let model_keys = self
            .models
            .iter()
            .map(|v| v.key().clone())
            .collect::<Vec<String>>();
        client_store
            .set_custom_value(ALL_MODELS_KEY.as_bytes(), serde_json::to_vec(&model_keys)?)
            .await?;

        trace!("sync done");

        Ok(())
    }
}
