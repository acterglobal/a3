use anyhow::Result;
use clap::{crate_version, Parser};

use effektio::{Client as EfkClient, CreateGroupSettingsBuilder};
use effektio_core::{
    matrix_sdk::{Client, ClientBuilder},
    ruma::{
        api::client::{
            account::register::v3::Request as RegistrationRequest,
            room::{
                create_room::v3::CreationContent, create_room::v3::Request as CreateRoomRequest,
                Visibility,
            },
            uiaa,
        },
        assign,
        room::RoomType,
        serde::Raw,
        OwnedRoomName, OwnedUserId, RoomAliasId, RoomName,
    },
    statics::default_effektio_group_states,
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
    cl.login(username, password, None, None).await?;
    Ok(EfkClient::new(cl, Default::default()))
}

/// Posting a news item to a given room
#[derive(Parser, Debug)]
pub struct Mock {
    #[clap()]
    pub homeserver: String,
}

impl Mock {
    pub async fn run(&self) -> Result<()> {
        let homeserver = self.homeserver.as_str();

        // FIXME: would be better if we used the effektio API for this...

        let admin = ensure_user(homeserver, "admin", "admin").await?;

        let sisko = ensure_user(homeserver, "sisko", "sisko").await?;
        let kyra = ensure_user(homeserver, "kyra", "kyra").await?;
        let worf = ensure_user(homeserver, "worf", "worf").await?;
        let bashir = ensure_user(homeserver, "bashir", "bashir").await?;
        let miles = ensure_user(homeserver, "miles", "miles").await?;
        let jadzia = ensure_user(homeserver, "jadzia", "jadzia").await?;
        let odo = ensure_user(homeserver, "odo", "odo").await?;

        let quark = ensure_user(homeserver, "quark", "quark").await?;
        let rom = ensure_user(homeserver, "rom", "rom").await?;
        let morn = ensure_user(homeserver, "morn", "morn").await?;
        let keiko = ensure_user(homeserver, "keiko", "keiko").await?;

        let team = [&sisko, &kyra, &worf, &bashir, &miles, &jadzia, &odo];
        let civilians = [&quark, &rom, &morn, &keiko];
        let quark_customers = [&quark, &rom, &morn, &jadzia, &kyra, &miles, &bashir];

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

        let everyones_ids: Vec<OwnedUserId> =
            futures::future::join_all(everyone.iter().map(|a| a.user_id()))
                .await
                .into_iter()
                .map(|a| a.expect("everyone here has an id"))
                .collect();

        log::warn!("Done ensuring users");

        let ops_settings = CreateGroupSettingsBuilder::default()
            .name(
                RoomName::parse("Ops")
                    .expect("static won't fail")
                    .to_owned(),
            )
            .alias("ops:ds9.effektio.org".to_owned())
            .invites(team_ids)
            .build()?;

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
            .name(
                RoomName::parse("Promenade")
                    .expect("static won't fail")
                    .to_owned(),
            )
            .alias("promenade:ds9.effektio.org".to_owned())
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
            .name(
                RoomName::parse("Quarks'")
                    .expect("static won't fail")
                    .to_owned(),
            )
            .alias("quarks:ds9.effektio.org".to_owned())
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

        log::warn!("Done creating spaces");

        let mut everyone = Vec::new();
        everyone.extend_from_slice(&team);
        everyone.extend_from_slice(&civilians);

        for member in everyone.iter() {
            member.sync_once(Default::default()).await?;
            for invited in member.invited_rooms().iter() {
                invited.accept_invitation().await?;
            }
        }
        log::warn!("Done accepting invites");

        Ok(())
    }
}
