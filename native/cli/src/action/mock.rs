use anyhow::Result;
use clap::{crate_version, Parser};

use effektio::{Client as EfkClient, CreateGroupSettingsBuilder};
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

fn default_client_config(homeserver: &str) -> Result<ClientBuilder> {
    let store_config = StoreConfig::new().state_store(MemoryStore::new());

    Ok(Client::builder()
        .user_agent(&format!("effektio-cli/{}", crate_version!()))
        .store_config(store_config)
        .homeserver_url(homeserver))
}

async fn register(homeserver: &str, username: &str, password: &str) -> Result<Client> {
    let client = default_client_config(homeserver)?.build().await?;
    if let Err(resp) = client.register(RegistrationRequest::new()).await {
        // FIXME: do actually check the registration types...
        if let Some(_response) = resp.uiaa_response() {
            let request = assign!(RegistrationRequest::new(), {
                username: Some(username),
                password: Some(password),

                auth: Some(uiaa::AuthData::Dummy(uiaa::Dummy::new())),
            });
            client.register(request).await?;
        }
    }

    Ok(client)
}

async fn ensure_user(homeserver: &str, username: &str, password: &str) -> Result<EfkClient> {
    let cl = match register(homeserver, username, password).await {
        Ok(cl) => cl,
        Err(e) => {
            log::warn!("Could not register {:}, {:}", username, e);
            default_client_config(homeserver)?.build().await?
        }
    };
    cl.login_username(username, password).send().await?;
    EfkClient::new(cl, Default::default()).await
}

#[derive(Parser, Debug)]
pub struct MockOpts {
    #[clap()]
    pub homeserver: String,
    #[clap(subcommand)]
    pub cmd: Option<MockCmd>,
}

#[derive(clap::Subcommand, Debug)]
pub enum MockCmd {
    All,
    Users,
    Spaces,
    AcceptInvites,
    // Conversations,
}

impl MockOpts {
    pub async fn run(&self) -> Result<()> {
        let homeserver = self.homeserver.clone();
        let m = Mock::new(homeserver).await?;
        match self.cmd {
            Some(MockCmd::Users) => {
                // happens on startup
            }
            Some(MockCmd::Spaces) => m.spaces().await?,
            Some(MockCmd::AcceptInvites) => m.accept_invitations().await?,
            Some(MockCmd::All) | None => {
                m.spaces().await?;
                m.accept_invitations().await?;
            }
        }
        Ok(())
    }
}

/// Posting a news item to a given room
#[derive(Debug, Clone)]
pub struct Mock {
    admin: EfkClient,
    sisko: EfkClient,
    kyra: EfkClient,
    worf: EfkClient,
    bashir: EfkClient,
    miles: EfkClient,
    jadzia: EfkClient,
    odo: EfkClient,
    quark: EfkClient,
    rom: EfkClient,
    morn: EfkClient,
    keiko: EfkClient,
}

impl Mock {
    pub async fn new(homeserver: String) -> Result<Self> {
        let admin = ensure_user(homeserver.as_str(), "admin", "admin").await?;

        let sisko = ensure_user(homeserver.as_str(), "sisko", "sisko").await?;
        let kyra = ensure_user(homeserver.as_str(), "kyra", "kyra").await?;
        let worf = ensure_user(homeserver.as_str(), "worf", "worf").await?;
        let bashir = ensure_user(homeserver.as_str(), "bashir", "bashir").await?;
        let miles = ensure_user(homeserver.as_str(), "miles", "miles").await?;
        let jadzia = ensure_user(homeserver.as_str(), "jadzia", "jadzia").await?;
        let odo = ensure_user(homeserver.as_str(), "odo", "odo").await?;

        let quark = ensure_user(homeserver.as_str(), "quark", "quark").await?;
        let rom = ensure_user(homeserver.as_str(), "rom", "rom").await?;
        let morn = ensure_user(homeserver.as_str(), "morn", "morn").await?;
        let keiko = ensure_user(homeserver.as_str(), "keiko", "keiko").await?;

        log::info!("Done ensuring users");

        Ok(Mock {
            admin,
            sisko,
            kyra,
            worf,
            bashir,
            miles,
            jadzia,
            odo,
            quark,
            rom,
            morn,
            keiko,
        })
    }

    pub fn team(&self) -> [&EfkClient; 7] {
        [
            &self.sisko,
            &self.kyra,
            &self.worf,
            &self.bashir,
            &self.miles,
            &self.jadzia,
            &self.odo,
        ]
    }
    pub fn civilians(&self) -> [&EfkClient; 4] {
        [&self.quark, &self.rom, &self.morn, &self.keiko]
    }

    pub fn quark_customers(&self) -> [&EfkClient; 7] {
        [
            &self.quark,
            &self.rom,
            &self.morn,
            &self.jadzia,
            &self.kyra,
            &self.miles,
            &self.bashir,
        ]
    }

    pub fn everyone(&self) -> Vec<&EfkClient> {
        let mut everyone = Vec::new();
        everyone.extend_from_slice(&self.team());
        everyone.extend_from_slice(&self.civilians());
        everyone
    }

    pub async fn spaces(&self) -> Result<()> {
        let team = self.team();
        let civilians = self.civilians();
        let quark_customers = self.quark_customers();

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

        let mut everyone = Vec::new();
        everyone.extend_from_slice(&team);
        everyone.extend_from_slice(&civilians);

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

        match self.admin.create_effektio_group(ops_settings).await {
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

        match self.admin.create_effektio_group(promenade_settings).await {
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

        match self.admin.create_effektio_group(quarks_settings).await {
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

    pub async fn accept_invitations(&self) -> Result<()> {
        for member in self.everyone().iter() {
            member.sync_once(Default::default()).await?;
            for invited in member.invited_rooms().iter() {
                invited.accept_invitation().await?;
            }
        }
        log::info!("Done accepting invites");

        Ok(())
    }
}
