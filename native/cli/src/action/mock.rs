use anyhow::{bail, Result};
use clap::{crate_version, Parser};
use effektio::{
    platform::sanitize,
    testing::{ensure_user, wait_for},
    Client as EfkClient, CreateGroupSettingsBuilder,
};
use effektio_core::{
    models::EffektioModel,
    ruma::{api::client::room::Visibility, OwnedUserId},
};
use matrix_sdk_base::store::{MemoryStore, StoreConfig};
use matrix_sdk_sled::make_store_config;
use std::collections::HashMap;

#[derive(Parser, Debug)]
pub struct MockOpts {
    /// Which homeserver are we running against
    #[clap(
        env = "DEFAULT_HOMESERVER_URL",
        default_value = "http://localhost:8118"
    )]
    pub homeserver: String,
    /// Which homeserver are we running against
    #[clap(env = "DEFAULT_HOMESERVER_NAME", default_value = "localhost")]
    pub server_name: String,

    /// Persist the store in .local/{user_id}
    #[clap(long)]
    pub persist: bool,

    //// export crypto database to .local for each known client
    #[clap(long)]
    pub export: bool,

    #[clap(subcommand)]
    pub cmd: Option<MockCmd>,
}

#[derive(clap::Subcommand, Debug)]
pub enum MockCmd {
    All,
    Users,
    Spaces,
    AcceptInvites,
    Tasks,
    // Conversations,
}

impl MockOpts {
    pub async fn run(&self) -> Result<()> {
        let homeserver = self.homeserver.clone();
        let server_name = self.server_name.clone();
        let mut m = Mock::new(homeserver, server_name, self.persist).await?;
        match self.cmd {
            Some(MockCmd::Users) => {
                m.everyone().await;
            }
            Some(MockCmd::Spaces) => m.spaces().await?,
            Some(MockCmd::AcceptInvites) => m.accept_invitations().await?,
            Some(MockCmd::Tasks) => m.tasks().await?,
            Some(MockCmd::All) | None => {
                m.spaces().await?;
                m.accept_invitations().await?;
                m.sync_up().await?;
                m.tasks().await?;
            }
        };
        if self.export {
            m.export().await?;
        }
        Ok(())
    }
}

/// Posting a news item to a given room
#[derive(Debug, Clone)]
pub struct Mock {
    persist: bool,
    users: HashMap<String, EfkClient>,
    server_name: String,
    homeserver: String,
}

impl Mock {
    async fn client(&mut self, username: String) -> Result<EfkClient> {
        match self.users.get(&username) {
            Some(c) => Ok(c.clone()),
            None => {
                tracing::trace!("client not found. creating for {:}", username);

                let store_config = if self.persist {
                    let path = sanitize(".local".to_string(), username.clone());
                    make_store_config(path, Some(&username)).await?
                } else {
                    StoreConfig::new().state_store(MemoryStore::new())
                };

                let user_agent = format!("effektio-cli/{}", crate_version!());

                let client = ensure_user(
                    self.homeserver.as_str(),
                    username.clone(),
                    user_agent,
                    store_config,
                )
                .await?;
                self.users.insert(username, client.clone());
                Ok(client)
            }
        }
    }
    pub async fn new(homeserver: String, server_name: String, persist: bool) -> Result<Self> {
        Ok(Mock {
            homeserver,
            persist,
            server_name,
            users: Default::default(),
        })
    }

    async fn team(&mut self) -> [EfkClient; 7] {
        [
            self.client("sisko".to_owned()).await.unwrap(),
            self.client("kyra".to_owned()).await.unwrap(),
            self.client("worf".to_owned()).await.unwrap(),
            self.client("bashir".to_owned()).await.unwrap(),
            self.client("miles".to_owned()).await.unwrap(),
            self.client("jadzia".to_owned()).await.unwrap(),
            self.client("odo".to_owned()).await.unwrap(),
        ]
    }
    async fn civilians(&mut self) -> [EfkClient; 4] {
        [
            self.client("quark".to_owned()).await.unwrap(),
            self.client("rom".to_owned()).await.unwrap(),
            self.client("morn".to_owned()).await.unwrap(),
            self.client("keiko".to_owned()).await.unwrap(),
        ]
    }

    async fn quark_customers(&mut self) -> [EfkClient; 7] {
        [
            self.client("quark".to_owned()).await.unwrap(),
            self.client("rom".to_owned()).await.unwrap(),
            self.client("morn".to_owned()).await.unwrap(),
            self.client("jadzia".to_owned()).await.unwrap(),
            self.client("kyra".to_owned()).await.unwrap(),
            self.client("miles".to_owned()).await.unwrap(),
            self.client("bashir".to_owned()).await.unwrap(),
        ]
    }

    async fn everyone(&mut self) -> Vec<EfkClient> {
        let mut everyone = Vec::new();
        everyone.extend_from_slice(&self.team().await);
        everyone.extend_from_slice(&self.civilians().await);
        everyone
    }

    pub async fn spaces(&mut self) -> Result<()> {
        let team = self.team().await;
        let civilians = self.civilians().await;
        let quark_customers = self.quark_customers().await;

        let team_ids: Vec<OwnedUserId> = team
            .iter()
            .map(|a| a.user_id())
            .map(|a| a.expect("everyone here has an id"))
            .collect();

        let civilians_ids: Vec<OwnedUserId> = civilians
            .iter()
            .map(|a| a.user_id())
            .map(|a| a.expect("everyone here has an id"))
            .collect();

        let quark_customer_ids: Vec<OwnedUserId> = quark_customers
            .iter()
            .map(|a| a.user_id())
            .map(|a| a.expect("everyone here has an id"))
            .collect();

        let everyone = self.everyone().await;

        let _everyones_ids: Vec<OwnedUserId> = everyone
            .iter()
            .map(|a| a.user_id())
            .map(|a| a.expect("everyone here has an id"))
            .collect();

        let ops_settings = Box::new(
            CreateGroupSettingsBuilder::default()
                .name("Ops".to_owned())
                .alias("ops".to_owned())
                .invites(team_ids)
                .build()?,
        );

        let admin = self.client("admin".to_owned()).await.unwrap();

        match admin.create_effektio_group(ops_settings).await {
            Ok(ops_id) => {
                tracing::info!("Ops Room Id: {:?}", ops_id);
            }
            Err(x) if x.is::<matrix_sdk::HttpError>() => {
                let inner = x
                    .downcast::<matrix_sdk::HttpError>()
                    .expect("already checked");
                tracing::warn!("Problem creating Ops Room: {:?}", inner);
            }
            Err(e) => {
                tracing::error!("Creating Ops Room failed: {:?}", e);
            }
        }

        let promenade_settings = Box::new(
            CreateGroupSettingsBuilder::default()
                .name("Promenade".to_owned())
                .alias("promenade".to_owned())
                .visibility(Visibility::Public)
                .invites(civilians_ids)
                .build()?,
        );

        match admin.create_effektio_group(promenade_settings).await {
            Ok(promenade_room_id) => {
                tracing::info!("Promenade Room Id: {:?}", promenade_room_id);
            }
            Err(x) if x.is::<matrix_sdk::HttpError>() => {
                let inner = x
                    .downcast::<matrix_sdk::HttpError>()
                    .expect("already checked");
                tracing::warn!("Problem creating Promenade Room: {:?}", inner);
            }
            Err(e) => {
                tracing::error!("Creating Promenade Room failed: {:?}", e);
            }
        }

        let quarks_settings = Box::new(
            CreateGroupSettingsBuilder::default()
                .name("Quarks'".to_owned())
                .alias("quarks".to_owned())
                .visibility(Visibility::Public)
                .invites(quark_customer_ids)
                .build()?,
        );

        match admin.create_effektio_group(quarks_settings).await {
            Ok(quarks_id) => {
                tracing::info!("Quarks Room Id: {:?}", quarks_id);
            }
            Err(x) if x.is::<matrix_sdk::HttpError>() => {
                let inner = x
                    .downcast::<matrix_sdk::HttpError>()
                    .expect("already checked");
                tracing::warn!("Problem creating Quarks Room: {:?}", inner);
            }
            Err(e) => {
                tracing::error!("Creating Quarks Room failed: {:?}", e);
            }
        }

        tracing::info!("Done creating spaces");
        Ok(())
    }

    pub async fn accept_invitations(&mut self) -> Result<()> {
        for member in self.everyone().await.iter() {
            tracing::info!("Accepting invites for {:}", member.user_id()?);
            member.sync_once(Default::default()).await?;
            for invited in member.invited_rooms().iter() {
                tracing::trace!("accepting {:#?}", invited);
                invited.accept_invitation().await?;
            }
        }
        tracing::info!("Done accepting invites");

        Ok(())
    }

    pub async fn sync_up(&mut self) -> Result<()> {
        for member in self.everyone().await.iter() {
            member.sync_once(Default::default()).await?;
            tracing::info!("Synced {:}", member.user_id()?);
        }
        Ok(())
    }

    fn local_alias(&self, name: &str) -> String {
        format!("{name}:{0}", self.server_name)
    }

    pub async fn tasks(&mut self) -> Result<()> {
        let list_name = "Daily Security Brief".to_owned();
        //let sisko = &self.sisko;
        let mut odo = self.client("odo".to_owned()).await?;
        //let kyra = &self.kyra;
        //sisko.sync_once(Default::default()).await?;
        let syncer = odo.start_sync();
        syncer.await_has_synced_history().await?;

        let task_lists = odo.task_lists().await?;
        let alias = self.local_alias("#ops");
        let task_list =
            if let Some(task_list) = task_lists.into_iter().find(|t| t.name() == list_name) {
                task_list
            } else {
                //kyra.sync_once(Default::default()).await?;

                let cloned_odo = odo.clone();
                let Some(odo_ops) = wait_for(move || {
                    let cloned_odo = cloned_odo.clone();
                    let alias = alias.clone();
                    async move {
                        println!("tasks get_group {alias}");
                        let group = cloned_odo.get_group(alias).await?;
                        Ok(Some(group))
                    }
                }).await? else {
                    bail!("Odo couldn't be found in Ops");
                };
                let mut draft = odo_ops.task_list_draft()?;

                let task_list_id = draft
                    .name(list_name)
                    .description_text("The tops of the daily security briefing with kyra".into())
                    .send()
                    .await?;

                let cloned_odo = odo.clone();
                wait_for(move || {
                    let cloned_odo = cloned_odo.clone();
                    let task_list_id = task_list_id.clone();
                    async move {
                        Ok(cloned_odo
                            .task_lists()
                            .await?
                            .into_iter()
                            .find(|e| e.event_id() == task_list_id))
                    }
                })
                .await?
                .expect("Task list not found even after polling for 3 seconds")
            };

        task_list
            .task_builder()?
            .title("Holding Cells review".into())
            .description_text(
                "What is the occupancy rate? Who is in the holding cells, for how much longer?"
                    .into(),
            )
            .send()
            .await?;

        task_list
            .task_builder()?
            .title("Special guests".into())
            .description_text("Any special guests expected, needing special attention?".into())
            .send()
            .await?;

        task_list
            .task_builder()?
            .title("Federation reports".into())
            .description_text("Daily status report from the federation".into())
            .send()
            .await?;

        tracing::info!("Creating task lists and tasks done.");

        Ok(())
    }

    pub async fn export(&mut self) -> Result<()> {
        std::fs::create_dir_all(".local")?;

        futures::future::try_join_all(self.users.values().map(|cl| async move {
            let full_username = cl.user_id().unwrap();
            let user_export_file = sanitize(
                ".local".to_string(),
                format!("mock_export_{full_username:}"),
            );

            cl.sync_once(Default::default()).await?;

            cl.encryption()
                .export_room_keys(user_export_file, "mock", |_| true)
                .await
        }))
        .await?;

        tracing::info!("Encryption keys exported to .local");

        Ok(())
    }
}
