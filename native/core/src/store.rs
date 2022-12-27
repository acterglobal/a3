use std::iter::FromIterator;

use crate::models::AnyEffektioModel;
use crate::{Error, Result};
use dashmap::mapref::one::RefMut;
use dashmap::DashMap;
use futures::future::try_join_all;
use matrix_sdk::{ruma::EventId, Client as MatrixClient};

#[derive(Clone, Debug)]
pub struct Store {
    client: MatrixClient,
    models: dashmap::DashMap<String, AnyEffektioModel>,
    indizes: dashmap::DashMap<String, Vec<String>>,
    dirty: dashmap::DashSet<String>,
}

async fn get_from_store(client: MatrixClient, key: &String) -> Result<AnyEffektioModel> {
    let v = client
        .store()
        .get_custom_value(format!("effektio:{:}", key).as_bytes())
        .await?
        .ok_or(Error::ModelNotFound)?;
    Ok(serde_json::from_slice::<AnyEffektioModel>(&v)?)
}

impl Store {
    pub async fn new(client: MatrixClient) -> Result<Self> {
        let models_vec = if let Some(v) = client
            .store()
            .get_custom_value("EFFEKTIO::ALL".as_bytes())
            .await?
            .map(|v| serde_json::from_slice::<Vec<String>>(&v))
            .transpose()?
        {
            try_join_all(v.iter().map(|k| get_from_store(client.clone(), k))).await?
        } else {
            Vec::new()
        };

        let indizes = DashMap::new();
        let mut models_sources = Vec::new();
        for m in models_vec {
            let key = m.key();
            for idx in m.indizes() {
                let mut r: RefMut<String, Vec<String>> = indizes.entry(idx).or_default();
                r.value_mut().push(key.clone())
            }
            models_sources.push((key, m));
        }

        let models = DashMap::from_iter(models_sources);

        Ok(Store {
            client,
            indizes,
            models,
            dirty: Default::default(),
        })
    }

    #[tracing::instrument]
    pub fn get_list(&self, key: &str) -> Result<impl Iterator<Item = AnyEffektioModel>> {
        let listing = if let Some(r) = self.indizes.get(key) {
            r.value().clone()
        } else {
            tracing::debug!(key = key, "No list found");
            vec![]
        };
        let models = self.models.clone();
        Ok(listing
            .into_iter()
            .filter_map(move |name| models.get(&name).map(|v| v.value().clone())))
    }

    pub async fn get(&self, evt_id: &EventId) -> Result<AnyEffektioModel> {
        Ok(self
            .models
            .get(&evt_id.to_string())
            .ok_or(Error::ModelNotFound)?
            .value()
            .clone())
    }

    #[tracing::instrument]
    pub async fn save(&self, mdl: AnyEffektioModel) -> Result<()> {
        let key = mdl.key();
        let mut indizes = mdl.indizes();
        if let Some(prev) = self.models.insert(key.clone(), mdl) {
            let mut remove_idzs = Vec::new();
            for idz in prev.indizes() {
                if let Some(idx) = indizes.iter().position(|i| i == &idz) {
                    indizes.remove(idx);
                } else {
                    remove_idzs.push(idz)
                }
            }

            for idz in remove_idzs {
                self.indizes
                    .get_mut(&idz)
                    .map(|mut v| v.value_mut().retain(|k| k != &key));
            }
        }
        for idx in indizes.into_iter() {
            tracing::trace!(idx = idx, key = key, "adding to index");
            self.indizes
                .entry(idx)
                .or_default()
                .value_mut()
                .push(key.clone());
        }
        self.dirty.insert(key);
        Ok(())
    }

    pub async fn sync(&self) -> Result<()> {
        for idx in self.dirty.iter() {
            let key = idx.key();
            if let Some(r) = self.models.get(key) {
                // FIXME: parallize
                self.client
                    .store()
                    .set_custom_value(
                        format!("effektio:{:}", key).as_bytes(),
                        serde_json::to_vec(r.value())?,
                    )
                    .await?;
            } else {
                tracing::warn!("Inconsistency error: {:} is missing", key);
            }
        }

        self.dirty.clear();
        Ok(())
    }
}
