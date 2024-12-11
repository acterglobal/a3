use acter::ActerModel;
use anyhow::{bail, Result};
use std::io::Write;
use tempfile::NamedTempFile;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user_with_template;

const TMPL: &str = r#"
version = "0.1"
name = "Smoketest Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }

[objects]
main_space = { type = "space", is-default = true, name = "{{ main.display_name }}’s pins test space"}

[objects.acter-website-pin]
type = "pin"
title = "Acter Website"
url = "https://acter.global"

[objects.acter-source-pin]
type = "pin"
title = "Acter Source Code"
url = "https://github.com/acterglobal/a3"

[objects.example-data-pin]
type = "pin"
title = "Acter example pin"
content = { body = "example pin data" }
"#;

#[tokio::test]
async fn pins_smoketest() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) = random_user_with_template("pin_smoke", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            if client.pins().await?.len() != 3 {
                bail!("not all pins found");
            }
            Ok(())
        }
    })
    .await?;

    assert_eq!(user.pins().await?.len(), 3);
    assert_eq!(user.pinned_links().await?.len(), 2);

    let spaces = user.spaces().await?;
    assert_eq!(spaces.len(), 1);

    let main_space = spaces.first().unwrap();
    assert_eq!(main_space.pins().await?.len(), 3);
    assert_eq!(main_space.pinned_links().await?.len(), 2);
    Ok(())
}

#[tokio::test]
async fn pin_comments() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) = random_user_with_template("pin_comments", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            if client.pins().await?.len() != 3 {
                bail!("not all pins found");
            }
            Ok(())
        }
    })
    .await?;

    let pin = user
        .pins()
        .await?
        .into_iter()
        .find(|p| !p.is_link())
        .expect("we’ve created one non-link pin");

    // START actual comment on pin

    let comments_manager = pin.comments().await?;
    assert!(!comments_manager.stats().has_comments());

    // ---- let’s make a comment

    let comments_listener = comments_manager.subscribe();
    let comment_1_id = comments_manager
        .comment_draft()?
        .content_text("I updated the pin".to_owned())
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if comments_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let comments = comments_manager.comments().await?;
    assert_eq!(comments.len(), 1);
    assert_eq!(comments[0].event_id(), comment_1_id);
    assert_eq!(comments[0].content().body, "I updated the pin".to_owned());

    Ok(())
}

#[tokio::test]
async fn pin_attachments() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) = random_user_with_template("pin_attachments", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            if client.pins().await?.len() != 3 {
                bail!("not all pins found");
            }
            Ok(())
        }
    })
    .await?;

    let pin = user
        .pins()
        .await?
        .into_iter()
        .find(|p| !p.is_link())
        .expect("we’ve created one non-link pin");

    // START actual attachment on pin

    let attachments_manager = pin.attachments().await?;
    assert!(!attachments_manager.stats().has_attachments());

    // ---- let’s make a attachment

    let bytes = include_bytes!("./fixtures/kingfisher.jpg");
    let mut jpg_file = NamedTempFile::new()?;
    jpg_file.as_file_mut().write_all(bytes)?;

    let attachments_listener = attachments_manager.subscribe();
    let base_draft = user.image_draft(
        jpg_file.path().to_string_lossy().to_string(),
        "image/jpeg".to_string(),
    );
    let attachment_1_id = attachments_manager
        .content_draft(Box::new(base_draft))
        .await?
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if attachments_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let attachments = attachments_manager.attachments().await?;
    assert_eq!(attachments.len(), 1);
    let attachment = attachments.first().unwrap();
    assert_eq!(attachment.event_id(), attachment_1_id);
    assert_eq!(attachment.type_str(), "image");

    // go for the second

    let bytes = include_bytes!("./fixtures/PNG_transparency_demonstration_1.png");
    let mut png_file = NamedTempFile::new()?;
    png_file.as_file_mut().write_all(bytes)?;

    let attachments_listener = attachments_manager.subscribe();
    let base_draft = user.file_draft(
        png_file.path().to_string_lossy().to_string(),
        "image/png".to_string(),
    );
    let attachment_2_id = attachments_manager
        .content_draft(Box::new(base_draft))
        .await?
        .send()
        .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if attachments_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let attachments = attachments_manager.attachments().await?;
    assert_eq!(attachments.len(), 2);
    let _attachment = attachments
        .iter()
        .find(|a| a.event_id() == attachment_2_id)
        .expect("File not found");
    // FIXME: for some reason this comes back as 'image'` rather than `file`
    // assert_eq!(attachment.type_str(), "file");
    // assert_eq!(
    //     attachment.file_desc().unwrap().name(),
    //     "effektio whitepaper"
    // );
    // assert_eq!(
    //     attachment.file_desc().unwrap().source().url(),
    //     "mxc://acter.global/tVLtaQaErMyoXmcCroPZdfNG"
    // );

    Ok(())
}

#[tokio::test]
async fn pin_external_link() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) = random_user_with_template("pin_comments", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            if client.pins().await?.len() != 3 {
                bail!("not all pins found");
            }
            Ok(())
        }
    })
    .await?;

    let pin = user
        .pins()
        .await?
        .into_iter()
        .find(|p| !p.is_link())
        .expect("we’ve created one non-link pin");

    // generate the external and internal links

    let internal_link = pin.internal_link();
    let external_link = pin.external_link().await?;

    let room_id = &pin.room_id().to_string()[1..];
    let pin_id = &pin.event_id().to_string()[1..];

    let path = format!("o/{room_id}/pin/{pin_id}");

    assert_eq!(internal_link, format!("acter:{path}"));

    let ext_url = url::Url::parse(&external_link)?;
    assert_eq!(ext_url.fragment().expect("must have fragment"), &path);
    Ok(())
}

#[tokio::test]
async fn pin_self_ref_attachments() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) = random_user_with_template("pin_attachments", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            if client.pins().await?.len() != 3 {
                bail!("not all pins found");
            }
            Ok(())
        }
    })
    .await?;

    let pin = user
        .pins()
        .await?
        .into_iter()
        .find(|p| !p.is_link())
        .expect("we’ve created one non-link pin");

    // START actual attachment on pin

    let attachments_manager = pin.attachments().await?;
    assert!(!attachments_manager.stats().has_attachments());

    let attachments_listener = attachments_manager.subscribe();

    // ---- let’s make an attachment by referencing the same pin -- cheeky
    let ref_details = pin.ref_details().await?;
    let attachment_1_id = attachments_manager
        .reference_draft(Box::new(ref_details))
        .await?
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if attachments_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let attachments = attachments_manager.attachments().await?;
    assert_eq!(attachments.len(), 1);
    let attachment = attachments.first().unwrap();
    assert_eq!(attachment.event_id(), attachment_1_id);
    assert_eq!(attachment.type_str(), "ref");

    Ok(())
}
