use acter_core::events::bookmarks::BookmarksEventContent;
use anyhow::Result;
use matrix_sdk::Account;

use crate::RUNTIME;

pub struct Bookmarks {
    inner: BookmarksEventContent,
    account: Account,
}

impl Bookmarks {
    pub fn entries(&self, key: String) -> Vec<String> {
        let lowered = key.to_lowercase();
        match lowered.as_str() {
            "pins" => self.inner.pins.clone(),
            "news" => self.inner.news.clone(),
            "events" => self.inner.events.clone(),
            "tasks" => self.inner.tasks.clone(),
            "task_lists" => self.inner.task_lists.clone(),
            _ => self.inner.other.get(&lowered).cloned().unwrap_or_default(),
        }
    }

    pub async fn add(&self, key: String, entry: String) -> Result<bool> {
        let mut inner = self.inner.clone();
        let lowered = key.to_lowercase();
        match lowered.as_str() {
            "pins" => {
                inner.pins.push(entry);
                inner.pins.dedup();
            }
            "news" => {
                inner.news.push(entry);
                inner.news.dedup();
            }
            "events" => {
                inner.events.push(entry);
                inner.events.dedup();
            }
            "tasks" => {
                inner.tasks.push(entry);
                inner.tasks.dedup();
            }
            "task_lists" => {
                inner.task_lists.push(entry);
                inner.task_lists.dedup();
            }
            _ => {
                inner
                    .other
                    .entry(lowered)
                    .and_modify(|entries| {
                        entries.push(entry.clone());
                        entries.dedup();
                    })
                    .or_insert_with(|| vec![entry]);
            }
        };

        self.submit(inner).await?;

        Ok(true)
    }

    pub async fn remove(&self, key: String, entry: String) -> Result<bool> {
        let mut inner = self.inner.clone();
        let lowered = key.to_lowercase();
        let has_updated = match lowered.as_str() {
            "pins" => {
                if let Some(pos) = inner.pins.iter().position(|e| e == &entry) {
                    inner.pins.remove(pos);
                    true
                } else {
                    false
                }
            }
            "news" => {
                if let Some(pos) = inner.news.iter().position(|e| e == &entry) {
                    inner.news.remove(pos);
                    true
                } else {
                    false
                }
            }
            "events" => {
                if let Some(pos) = inner.events.iter().position(|e| e == &entry) {
                    inner.events.remove(pos);
                    true
                } else {
                    false
                }
            }
            "tasks" => {
                if let Some(pos) = inner.tasks.iter().position(|e| e == &entry) {
                    inner.tasks.remove(pos);
                    true
                } else {
                    false
                }
            }
            "task_lists" => {
                if let Some(pos) = inner.task_lists.iter().position(|e| e == &entry) {
                    inner.task_lists.remove(pos);
                    true
                } else {
                    false
                }
            }
            _ => {
                if let Some(entries) = inner.other.get_mut(&lowered) {
                    if let Some(pos) = entries.iter().position(|e| e == &entry) {
                        entries.remove(pos);
                        true
                    } else {
                        false
                    }
                } else {
                    false
                }
            }
        };
        if (has_updated) {
            self.submit(inner).await?;
        }

        Ok(has_updated)
    }

    async fn submit(&self, content: BookmarksEventContent) -> Result<()> {
        let account = self.account.clone();
        let resp = RUNTIME
            .spawn(async move { account.set_account_data(content).await })
            .await??;
        Ok(())
    }
}

impl crate::Account {
    pub async fn bookmarks(&self) -> Result<Bookmarks> {
        let account = self.account.clone();
        RUNTIME
            .spawn(async move {
                let inner = if let Some(o) = account.account_data::<BookmarksEventContent>().await?
                {
                    o.deserialize()?
                } else {
                    Default::default()
                };

                anyhow::Ok(Bookmarks { inner, account })
            })
            .await?
    }
}
