use std::collections::HashMap;

use anyhow::Result;
use clap::{crate_version, Parser};

use effektio::{platform::sanitize, Client as EfkClient, CreateGroupSettingsBuilder};
use effektio_core::{
    matrix_sdk::{Client, ClientBuilder},
    ruma::{
        api::client::{
            account::register::v3::Request as RegistrationRequest, room::Visibility, uiaa,
        },
        assign, OwnedUserId,
    },
};
use matrix_sdk_base::store::{MemoryStore, StoreConfig};
use matrix_sdk_sled::make_store_config;

async fn default_client_config(
    homeserver: &str,
    username: &str,
    persist: bool,
) -> Result<ClientBuilder> {
    let store_config = if persist {
        let path = sanitize(".local".to_string(), format!("{:}", username));
        make_store_config(path, Some(username)).await?
    } else {
        StoreConfig::new().state_store(MemoryStore::new())
    };

    Ok(Client::builder()
        .user_agent(&format!("effektio-cli/{}", crate_version!()))
        .store_config(store_config)
        .homeserver_url(homeserver))
}

async fn register(homeserver: &str, username: String, persist: bool) -> Result<Client> {
    let client = default_client_config(homeserver, &username, persist)
        .await?
        .build()
        .await?;
    if let Err(resp) = client.register(RegistrationRequest::new()).await {
        // FIXME: do actually check the registration types...
        if let Some(_response) = resp.as_uiaa_response() {
            let request = assign!(RegistrationRequest::new(), {
                username: Some(username.clone()),
                password: Some(username),

                auth: Some(uiaa::AuthData::Dummy(uiaa::Dummy::new())),
            });
            client.register(request).await?;
        }
    }

    Ok(client)
}

async fn ensure_user(homeserver: &str, username: String, persist: bool) -> Result<EfkClient> {
    let cl = match register(homeserver, username.clone(), persist).await {
        Ok(cl) => cl,
        Err(e) => {
            log::warn!("Could not register {:}, {:}", username, e);
            default_client_config(homeserver, &username, persist)
                .await?
                .build()
                .await?
        }
    };
    cl.login_username(username.clone(), &username)
        .send()
        .await?;

    EfkClient::new(cl, Default::default()).await
}

#[derive(Parser, Debug)]
pub struct MockOpts {
    /// Which homeserver are we running against
    #[clap(env = "EFFEKTIO_HOMESERVER")]
    pub homeserver: String,

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
        let mut m = Mock::new(homeserver, self.persist).await?;
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
    homeserver: String,
}

impl Mock {
    async fn client(&mut self, username: String) -> Result<EfkClient> {
        match self.users.get(&username) {
            Some(c) => Ok(c.clone()),
            None => {
                log::trace!("client not found. creating for {:}", username);
                let client =
                    ensure_user(self.homeserver.as_str(), username.clone(), self.persist).await?;
                self.users.insert(username, client.clone());
                Ok(client)
            }
        }
    }
    pub async fn new(homeserver: String, persist: bool) -> Result<Self> {
        Ok(Mock {
            homeserver,
            persist,
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

        let team_ids: Vec<OwnedUserId> =
            futures::future::join_all(team.iter().map(|a| a.user_id()))
                .await
                .into_iter()
                .map(|a| a.expect("everyone here has an id"))
                .collect();

        let civilians_ids: Vec<OwnedUserId> =
            futures::future::join_all(civilians.iter().map(|a| a.user_id()))
                .await
                .into_iter()
                .map(|a| a.expect("everyone here has an id"))
                .collect();

        let quark_customer_ids: Vec<OwnedUserId> =
            futures::future::join_all(quark_customers.iter().map(|a| a.user_id()))
                .await
                .into_iter()
                .map(|a| a.expect("everyone here has an id"))
                .collect();

        let everyone = self.everyone().await;

        let _everyones_ids: Vec<OwnedUserId> =
            futures::future::join_all(everyone.iter().map(|a| a.user_id()))
                .await
                .into_iter()
                .map(|a| a.expect("everyone here has an id"))
                .collect();

        let ops_settings = CreateGroupSettingsBuilder::default()
            .name("Ops".to_owned())
            .alias("ops".to_owned())
            .invites(team_ids)
            .build()?;

        let admin = self.client("admin".to_owned()).await.unwrap();

        match admin.create_effektio_group(ops_settings).await {
            Ok(ops_id) => {
                log::info!("Ops Room Id: {:?}", ops_id);
            }
            Err(x) if x.is::<matrix_sdk::HttpError>() => {
                let inner = x
                    .downcast::<matrix_sdk::HttpError>()
                    .expect("already checked");
                log::warn!("Problem creating Ops Room: {:?}", inner);
            }
            Err(e) => {
                log::error!("Creating Ops Room failed: {:?}", e);
            }
        }

        let promenade_settings = CreateGroupSettingsBuilder::default()
            .name("Promenade".to_owned())
            .alias("promenade".to_owned())
            .visibility(Visibility::Public)
            .invites(civilians_ids)
            .build()?;

        match admin.create_effektio_group(promenade_settings).await {
            Ok(promenade_room_id) => {
                log::info!("Promenade Room Id: {:?}", promenade_room_id);
            }
            Err(x) if x.is::<matrix_sdk::HttpError>() => {
                let inner = x
                    .downcast::<matrix_sdk::HttpError>()
                    .expect("already checked");
                log::warn!("Problem creating Promenade Room: {:?}", inner);
            }
            Err(e) => {
                log::error!("Creating Promenade Room failed: {:?}", e);
            }
        }

        let quarks_settings = CreateGroupSettingsBuilder::default()
            .name("Quarks'".to_owned())
            .alias("quarks".to_owned())
            .visibility(Visibility::Public)
            .invites(quark_customer_ids)
            .build()?;

        match admin.create_effektio_group(quarks_settings).await {
            Ok(quarks_id) => {
                log::info!("Quarks Room Id: {:?}", quarks_id);
            }
            Err(x) if x.is::<matrix_sdk::HttpError>() => {
                let inner = x
                    .downcast::<matrix_sdk::HttpError>()
                    .expect("already checked");
                log::warn!("Problem creating Quarks Room: {:?}", inner);
            }
            Err(e) => {
                log::error!("Creating Quarks Room failed: {:?}", e);
            }
        }

        log::info!("Done creating spaces");
        Ok(())
    }

    pub async fn accept_invitations(&mut self) -> Result<()> {
        for member in self.everyone().await.iter() {
            log::info!("Accepting invites for {:}", member.user_id().await?);
            member.sync_once(Default::default()).await?;
            for invited in member.invited_rooms().iter() {
                log::info!("accepting {:#?}", invited);
                invited.accept_invitation().await?;
            }
        }
        log::info!("Done accepting invites");

        Ok(())
    }

    pub async fn sync_up(&mut self) -> Result<()> {
        for member in self.everyone().await.iter() {
            member.sync_once(Default::default()).await?;
            log::info!("Synced {:}", member.user_id().await?);
        }
        Ok(())
    }

    pub async fn tasks(&mut self) -> Result<()> {
        //let sisko = &self.sisko;
        let odo = self.client("odo".to_owned()).await?;
        //let kyra = &self.kyra;
        //sisko.sync_once(Default::default()).await?;
        odo.sync_once(Default::default()).await?;
        //kyra.sync_once(Default::default()).await?;

        let odo_ops = odo.get_group("#ops:ds9.effektio.org".into()).await?;
        let mut draft = odo_ops.task_list_draft()?;

        let task_list_id = draft
            .name("Daily Security Brief".into())
            .description("The tops of the daily security briefing with kyra".into())
            .send()
            .await?;

        odo.sync_once(Default::default()).await?;

        let task_list = odo
            .task_lists()
            .await?
            .into_iter()
            .find(|e| e.event_id == task_list_id)
            .unwrap();

        task_list
            .task_builder()
            .title("Holding Cells review".into())
            .description(
                "What is the occupancy rate? Who is in the holding cells, for how much longer?"
                    .into(),
            )
            .send()
            .await?;

        task_list
            .task_builder()
            .title("Special guests".into())
            .description("Any special guests expected, needing special attention?".into())
            .send()
            .await?;

        task_list
            .task_builder()
            .title("Federation reports".into())
            .description("Daily status report from the federation".into())
            .send()
            .await?;

        log::info!("Creating task lists and tasks done.");

        Ok(())
    }

    pub async fn export(&mut self) -> anyhow::Result<()> {
        std::fs::create_dir_all(".local")?;

        futures::future::try_join_all(self.users.values().map(|cl| async move {
            let full_username = cl.user_id().await.unwrap();
            let user_export_file = sanitize(
                ".local".to_string(),
                format!("mock_export_{:}", full_username),
            );

            cl.sync_once(Default::default()).await?;

            cl.encryption()
                .export_room_keys(user_export_file, "mock", |_| true)
                .await
        }))
        .await?;

        log::info!("Encryption keys exported to .local");

        Ok(())
    }
}
