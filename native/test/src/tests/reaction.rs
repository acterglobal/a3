use acter::api::login_new_client;
use anyhow::Result;
use futures::stream::StreamExt;
use tempfile::TempDir;

#[tokio::test]
async fn sisko_reads_msg_reactions() -> Result<()> {
    let _ = env_logger::try_init();
    let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME")
        .unwrap_or("localhost")
        .to_string();
    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL")
        .unwrap_or("http://localhost:8118")
        .to_string();

    let tmp_dir = TempDir::new()?;
    let mut sisko = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "@sisko".to_string(),
        "sisko".to_string(),
        homeserver_name.clone(),
        homeserver_url.clone(),
        Some("SISKO_DEV".to_string()),
    )
    .await?;
    let sisko_syncer = sisko.start_sync();
    let mut sisko_synced = sisko_syncer.first_synced_rx().expect("note yet read");
    while sisko_synced.next().await != Some(true) {} // let's wait for it to have synced
    let sisko_group = sisko
        .get_group(format!("#ops:{homeserver_name}"))
        .await
        .expect("sisko should belong to ops");
    let event_id = sisko_group
        .send_plain_message("Hi, everyone".to_string())
        .await?;

    let tmp_dir = TempDir::new()?;
    let mut kyra = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "@kyra".to_string(),
        "kyra".to_string(),
        homeserver_name.clone(),
        homeserver_url.clone(),
        Some("KYRA_DEV".to_string()),
    )
    .await?;
    let kyra_syncer = kyra.start_sync();
    let mut first_synced = kyra_syncer.first_synced_rx().expect("note yet read");
    while first_synced.next().await != Some(true) {} // let's wait for it to have synced
    let kyra_group = kyra
        .get_group(format!("#ops:{homeserver_name}"))
        .await
        .expect("kyra should belong to ops");

    let tmp_dir = TempDir::new()?;
    let mut worf = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "@worf".to_string(),
        "worf".to_string(),
        homeserver_name.clone(),
        homeserver_url.clone(),
        Some("WORF_DEV".to_string()),
    )
    .await?;
    let worf_syncer = worf.start_sync();
    let mut first_synced = worf_syncer.first_synced_rx().expect("note yet read");
    while first_synced.next().await != Some(true) {} // let's wait for it to have synced
    let worf_group = worf
        .get_group(format!("#ops:{homeserver_name}"))
        .await
        .expect("worf should belong to ops");

    let tmp_dir = TempDir::new()?;
    let mut bashir = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "@bashir".to_string(),
        "bashir".to_string(),
        homeserver_name.clone(),
        homeserver_url.clone(),
        Some("BASHIR_DEV".to_string()),
    )
    .await?;
    let bashir_syncer = bashir.start_sync();
    let mut first_synced = bashir_syncer.first_synced_rx().expect("note yet read");
    while first_synced.next().await != Some(true) {} // let's wait for it to have synced
    let bashir_group = bashir
        .get_group(format!("#ops:{homeserver_name}"))
        .await
        .expect("bashir should belong to ops");

    let tmp_dir = TempDir::new()?;
    let mut miles = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "@miles".to_string(),
        "miles".to_string(),
        homeserver_name.clone(),
        homeserver_url.clone(),
        Some("MILES_DEV".to_string()),
    )
    .await?;
    let miles_syncer = miles.start_sync();
    let mut first_synced = miles_syncer.first_synced_rx().expect("note yet read");
    while first_synced.next().await != Some(true) {} // let's wait for it to have synced
    let miles_group = miles
        .get_group(format!("#ops:{homeserver_name}"))
        .await
        .expect("miles should belong to ops");

    let tmp_dir = TempDir::new()?;
    let mut jadzia = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "@jadzia".to_string(),
        "jadzia".to_string(),
        homeserver_name.clone(),
        homeserver_url.clone(),
        Some("JADZIA_DEV".to_string()),
    )
    .await?;
    let jadzia_syncer = jadzia.start_sync();
    let mut first_synced = jadzia_syncer.first_synced_rx().expect("note yet read");
    while first_synced.next().await != Some(true) {} // let's wait for it to have synced
    let jadzia_group = jadzia
        .get_group(format!("#ops:{homeserver_name}"))
        .await
        .expect("jadzia should belong to ops");

    let tmp_dir = TempDir::new()?;
    let mut odo = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_string(),
        "@odo".to_string(),
        "odo".to_string(),
        homeserver_name.clone(),
        homeserver_url.clone(),
        Some("ODO_DEV".to_string()),
    )
    .await?;
    let odo_syncer = odo.start_sync();
    let mut first_synced = odo_syncer.first_synced_rx().expect("note yet read");
    while first_synced.next().await != Some(true) {} // let's wait for it to have synced
    let odo_group = odo
        .get_group(format!("#ops:{homeserver_name}"))
        .await
        .expect("odo should belong to ops");

    kyra_group
        .send_reaction(event_id.to_string(), "👏".to_string())
        .await?;
    worf_group
        .send_reaction(event_id.to_string(), "😎".to_string())
        .await?;
    bashir_group
        .send_reaction(event_id.to_string(), "😜".to_string())
        .await?;
    miles_group
        .send_reaction(event_id.to_string(), "🤩".to_string())
        .await?;
    jadzia_group
        .send_reaction(event_id.to_string(), "😍".to_string())
        .await?;
    odo_group
        .send_reaction(event_id.to_string(), "😂".to_string())
        .await?;

    let event = sisko_group.event(&event_id).await?;
    println!("reactions: {event:?}");

    Ok(())
}
