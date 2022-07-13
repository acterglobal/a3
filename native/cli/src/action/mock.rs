use anyhow::Result;
use clap::{crate_version, Parser};

use effektio_core::matrix_sdk::{Client, ClientBuilder};
use matrix_sdk_base::store::{MemoryStore, StoreConfig};

use effektio_core::ruma::{
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
};

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

async fn ensure_user(homeserver: &str, username: &str, password: &str) -> Result<Client> {
    let cl = match register(homeserver, username, password).await {
        Ok(cl) => cl,
        Err(e) => {
            log::warn!("Could not register {:}, {:}", username, e);
            default_client_config(homeserver)?.build().await?
        }
    };
    cl.login(username, password, None, None).await?;
    Ok(cl)
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

        let team = [
            sisko.user_id().expect("siskos UserId is set").to_owned(),
            kyra.user_id().expect("kyras UserId is set").to_owned(),
            worf.user_id().expect("worfs' UserId is set").to_owned(),
            bashir.user_id().expect("bashirs userId is set").to_owned(),
            miles.user_id().expect("miles UserId is set").to_owned(),
            jadzia.user_id().expect("jadzia UserId is set").to_owned(),
            odo.user_id().expect("odos UserId is set").to_owned(),
        ];

        let quark = ensure_user(homeserver, "quark", "quark").await?;
        let rom = ensure_user(homeserver, "rom", "rom").await?;
        let morn = ensure_user(homeserver, "morn", "morn").await?;
        let _keiko = ensure_user(homeserver, "keiko", "keiko").await?;

        log::warn!("Done ensuring users");

        let prom_name = "Promenade".to_owned();

        let _promenade = admin
            .create_room(assign!(CreateRoomRequest::new(), {
                creation_content: Some(Raw::new(&assign!(CreationContent::new(), {
                    room_type: Some(RoomType::Space)
                }))?),
                is_direct: false,
                invite: &team,
                name: Some(&prom_name),
                visibility: Visibility::Public,
            }))
            .await?;

        let quark_customers = [
            quark.user_id().expect("quarks UserId is set").to_owned(),
            rom.user_id().expect("roms UserId is set").to_owned(),
            morn.user_id().expect("morns UserId is set").to_owned(),
            jadzia.user_id().expect("jadzias UserId is set").to_owned(),
        ];

        let quarks_name = "Quarks'".to_owned();
        // let quarks_states = [
        //     Raw::new(
        //         assign!(SpaceParentEventContent::new(), {

        //         }
        //     )?
        // ];

        let _quarks = admin
            .create_room(assign!(CreateRoomRequest::new(), {
                creation_content: Some(Raw::new(&assign!(CreationContent::new(), {
                    room_type: Some(RoomType::Space)
                }))?),
                // initial_state: &quarks_states
                is_direct: false,
                invite: &quark_customers,
                name: Some(&quarks_name),
                visibility: Visibility::Public,
            }))
            .await?;

        log::warn!("Done creating spaces");

        Ok(())
    }
}
