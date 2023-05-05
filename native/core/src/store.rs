use dashmap::{mapref::one::RefMut, DashMap};
use futures::future::{join_all, try_join_all};
use matrix_sdk::Client as MatrixClient;
use std::{iter::FromIterator, sync::Arc};

use crate::{
    models::{ActerModel, AnyActerModel},
    Error, Result,
};

#[derive(Clone, Debug)]
pub struct Store {
    client: MatrixClient,
    fresh: bool,
    models: Arc<dashmap::DashMap<String, AnyActerModel>>,
    indizes: Arc<dashmap::DashMap<String, Vec<String>>>,
    dirty: Arc<dashmap::DashSet<String>>,
}

static ALL_MODELS_KEY: &str = "ACTER::ALL";
static DB_VERSION_KEY: &str = "ACTER::DB_VERSION";
static CURRENT_DB_VERSION: u32 = 1;

async fn get_from_store<T: serde::de::DeserializeOwned>(
    client: MatrixClient,
    key: &str,
) -> Result<T> {
    let v = client
        .store()
        .get_custom_value(format!("acter:{key}").as_bytes())
        .await?
        .ok_or(Error::ModelNotFound)?;
    Ok(serde_json::from_slice(v.as_slice())?)
}

impl Store {
    pub async fn get_raw<T: serde::de::DeserializeOwned>(&self, key: &str) -> Result<T> {
        if self.fresh {
            return Err(Error::ModelNotFound);
        }
        get_from_store(self.client.clone(), key).await
    }

    pub async fn set_raw<T: serde::Serialize>(&self, key: &str, value: &T) -> Result<()> {
        tracing::trace!(key, "set_raw");
        self.client
            .store()
            .set_custom_value(
                format!("acter:{key}").as_bytes(),
                serde_json::to_vec(value)?,
            )
            .await?;
        Ok(())
    }

    pub async fn new(client: MatrixClient) -> Result<Self> {
        if client
            .store()
            .get_custom_value(DB_VERSION_KEY.as_bytes())
            .await
            .map_err(|e| crate::Error::Custom(format!("failed to find DB version key: {e}")))?
            .map(|u| u32::from_le_bytes(u.as_chunks().0[0]))
            .unwrap_or_default()
            < CURRENT_DB_VERSION
        {
            // "upgrading" by resetting
            client
                .store()
                .set_custom_value(ALL_MODELS_KEY.as_bytes(), vec![])
                .await
                .map_err(|e| {
                    crate::Error::Custom(format!("setting all models to [] failed: {e}"))
                })?;

            client
                .store()
                .set_custom_value(
                    DB_VERSION_KEY.as_bytes(),
                    CURRENT_DB_VERSION.to_le_bytes().to_vec(),
                )
                .await
                .map_err(|e| crate::Error::Custom(format!("setting db version failed: {e}")))?;

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
            .map_err(|e| {
                crate::Error::Custom(format!("deserializing all models index failed: {e}"))
            })?;
        let models_vec = if let Some(v) = data {
            let items = v
                .iter()
                .map(|k| get_from_store::<AnyActerModel>(client.clone(), k));
            try_join_all(items).await?
        } else {
            vec![]
        };

        let indizes = Arc::new(DashMap::new());
        let mut models_sources = Vec::new();
        for m in models_vec {
            let key = m.event_id().to_string();
            for idx in m.indizes() {
                let mut r: RefMut<String, Vec<String>> = indizes.entry(idx).or_default();
                r.value_mut().push(key.clone())
            }
            models_sources.push((key, m));
        }

        let models = Arc::new(DashMap::from_iter(models_sources));

        Ok(Store {
            fresh: false,
            client,
            indizes,
            models,
            dirty: Default::default(),
        })
    }

    #[tracing::instrument(skip(self))]
    pub async fn get_list(&self, key: &str) -> Result<impl Iterator<Item = AnyActerModel>> {
        let listing = if let Some(r) = self.indizes.get(key) {
            r.value().clone()
        } else {
            tracing::debug!(user=?self.client.user_id(), key, "No list found");
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
            .ok_or(Error::ModelNotFound)?
            .value()
            .clone();
        Ok(m)
    }

    pub async fn get_many(&self, model_keys: Vec<String>) -> Vec<Option<AnyActerModel>> {
        let models = model_keys.iter().map(|k| async { self.get(k).await.ok() });
        join_all(models).await
    }

    #[tracing::instrument(skip(self))]
    pub async fn save_model_inner(&self, mdl: AnyActerModel) -> Result<Vec<String>> {
        let key = mdl.event_id().to_string();
        let mut keys_changed = vec![key.clone()];
        tracing::trace!(user=?self.client.user_id(), key, "saving");
        let mut indizes = mdl.indizes();
        if let Some(prev) = self.models.insert(key.clone(), mdl) {
            tracing::trace!(user=?self.client.user_id(), key, "previous model found");
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
            tracing::trace!(user = ?self.client.user_id(), idx, key, exists=self.indizes.contains_key(&idx), "adding to index");
            self.indizes
                .entry(idx.clone())
                .or_default()
                .value_mut()
                .push(key.clone());
            tracing::trace!(user = ?self.client.user_id(), idx, key, "added to index");
            keys_changed.push(idx);
        }
        tracing::trace!(user=?self.client.user_id(), key, "saved");
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
        for idx in self.dirty.iter() {
            let key = idx.key();
            if let Some(r) = self.models.get(key) {
                // FIXME: parallize
                self.client
                    .store()
                    .set_custom_value(
                        format!("acter:{key:}").as_bytes(),
                        serde_json::to_vec(r.value())?,
                    )
                    .await?;
            } else {
                tracing::warn!(key, "Inconsistency error: key is missing");
            }
        }

        self.dirty.clear();
        let model_keys = self
            .models
            .iter()
            .map(|v| v.key().clone())
            .collect::<Vec<String>>();
        self.client
            .store()
            .set_custom_value(ALL_MODELS_KEY.as_bytes(), serde_json::to_vec(&model_keys)?)
            .await?;

        Ok(())
    }
}
