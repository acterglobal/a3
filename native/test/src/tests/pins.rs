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
main_space = { type = "space", is-default = true, name = "{{ main.display_name }}’s pins test space" }

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
    Retry::spawn(retry_strategy, || async {
        if user.pins().await?.len() != 3 {
            bail!("not all pins found");
        }
        Ok(())
    })
    .await?;

    let pins = user.pins().await?;
    assert_eq!(pins.len(), 3);

    let first_pin = pins.first().unwrap();
    let user_id = user.user_id()?;
    assert_eq!(first_pin.sender(), user_id);

    let spaces = user.spaces().await?;
    assert_eq!(spaces.len(), 1);

    let main_space = spaces.first().expect("main space should be available");
    assert_eq!(main_space.pins().await?.len(), 3);
    Ok(())
}

#[tokio::test]
async fn pin_comments() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) = random_user_with_template("pin_comments", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        if user.pins().await?.len() != 3 {
            bail!("not all pins found");
        }
        Ok(())
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
    let body = "I updated the pin";
    let comment_id = comments_manager
        .comment_draft()?
        .content_text(body.to_owned())
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        if comments_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let comments = comments_manager.comments().await?;
    assert_eq!(comments.len(), 1);
    assert_eq!(comments[0].event_id(), comment_id);
    assert_eq!(comments[0].content().body, body);

    Ok(())
}

#[tokio::test]
async fn pin_attachments() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) = random_user_with_template("pin_attachments", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        if user.pins().await?.len() != 3 {
            bail!("not all pins found");
        }
        Ok(())
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
    let mimetype = "image/jpeg";
    let base_draft = user.image_draft(
        jpg_file.path().to_string_lossy().to_string(),
        mimetype.to_owned(),
    );
    let jpg_attach_id = attachments_manager
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
    let attachment = attachments
        .first()
        .expect("first attachment should be available");
    assert_eq!(attachment.event_id(), jpg_attach_id);
    assert_eq!(attachment.type_str(), "image");
    assert_eq!(
        attachment
            .msg_content()
            .and_then(|c| c.mimetype())
            .as_deref(),
        Some(mimetype)
    );

    // go for the second

    let bytes = include_bytes!("./fixtures/PNG_transparency_demonstration_1.png");
    let mut png_file = NamedTempFile::new()?;
    png_file.as_file_mut().write_all(bytes)?;

    let attachments_listener = attachments_manager.subscribe();
    let mimetype = "image/png";
    let base_draft = user.file_draft(
        png_file.path().to_string_lossy().to_string(),
        mimetype.to_owned(),
    );
    let png_attach_id = attachments_manager
        .content_draft(Box::new(base_draft))
        .await?
        .send()
        .await?;

    Retry::spawn(retry_strategy, || async {
        if attachments_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let attachments = attachments_manager.attachments().await?;
    assert_eq!(attachments.len(), 2);
    let attachment = attachments
        .into_iter()
        .find(|a| a.event_id() == png_attach_id)
        .expect("File not found");
    assert_eq!(
        attachment
            .msg_content()
            .and_then(|c| c.mimetype())
            .as_deref(),
        Some(mimetype)
    );

    // FIXME: for some reason this comes back as `image` rather than `file`
    // assert_eq!(attachment.type_str(), "file");
    // assert_eq!(
    //     attachment.file_desc().expect("file description should be available").name(),
    //     "effektio whitepaper"
    // );
    // assert_eq!(
    //     attachment.file_desc().expect("file description should be available").source().url(),
    //     "mxc://acter.global/tVLtaQaErMyoXmcCroPZdfNG"
    // );

    // go for the third

    let bytes = include_bytes!("./fixtures/sample-3s.mp3");
    let mut mp3_file = NamedTempFile::new()?;
    mp3_file.as_file_mut().write_all(bytes)?;

    let attachments_listener = attachments_manager.subscribe();
    let mimetype = "audio/mp3";
    let base_draft = user.audio_draft(
        mp3_file.path().to_string_lossy().to_string(),
        mimetype.to_owned(),
    );
    let mp3_attach_id = attachments_manager
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
    assert_eq!(attachments.len(), 3);
    let attachment = attachments
        .into_iter()
        .find(|a| a.event_id() == mp3_attach_id)
        .expect("File not found");
    assert_eq!(attachment.event_id(), mp3_attach_id);
    assert_eq!(attachment.type_str(), "audio");
    assert_eq!(
        attachment
            .msg_content()
            .and_then(|c| c.mimetype())
            .as_deref(),
        Some(mimetype)
    );

    // go for the fourth

    let bytes = include_bytes!("./fixtures/big_buck_bunny.mp4");
    let mut mp4_file = NamedTempFile::new()?;
    mp4_file.as_file_mut().write_all(bytes)?;

    let attachments_listener = attachments_manager.subscribe();
    let mimetype = "video/mpeg4";
    let base_draft = user.video_draft(
        mp4_file.path().to_string_lossy().to_string(),
        mimetype.to_owned(),
    );
    let mp4_attach_id = attachments_manager
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
    assert_eq!(attachments.len(), 4);
    let attachment = attachments
        .into_iter()
        .find(|a| a.event_id() == mp4_attach_id)
        .expect("File not found");
    assert_eq!(attachment.event_id(), mp4_attach_id);
    assert_eq!(attachment.type_str(), "video");
    assert_eq!(
        attachment
            .msg_content()
            .and_then(|c| c.mimetype())
            .as_deref(),
        Some(mimetype)
    );

    // go for the fifth

    let attachments_listener = attachments_manager.subscribe();
    let url = "https://acter.global";
    let link_attach_id = attachments_manager
        .link_draft(url.to_owned(), Some("Acter Website".to_owned()))
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
    assert_eq!(attachments.len(), 5);
    let attachment = attachments
        .into_iter()
        .find(|a| a.event_id() == link_attach_id)
        .expect("Link not found");
    assert_eq!(attachment.event_id(), link_attach_id);
    assert_eq!(attachment.type_str(), "link");
    assert_eq!(
        attachment.msg_content().map(|c| c.body()).as_deref(),
        Some(url)
    );

    Ok(())
}

#[tokio::test]
async fn pin_external_link() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) = random_user_with_template("pin_comments", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        if user.pins().await?.len() != 3 {
            bail!("not all pins found");
        }
        Ok(())
    })
    .await?;

    let pin = user
        .pins()
        .await?
        .into_iter()
        .find(|p| !p.is_link())
        .expect("we’ve created one non-link pin");

    // generate the external and internal links

    let ref_details = pin.ref_details().await?;

    let internal_link = ref_details.generate_internal_link(false)?;
    let external_link = ref_details.generate_external_link().await?;

    let room_id = &pin.room_id().to_string()[1..];
    let pin_id = &pin.event_id().to_string()[1..];

    let path = format!("o/{room_id}/pin/{pin_id}");

    assert_eq!(internal_link, format!("acter:{path}?via=localhost"));

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
    Retry::spawn(retry_strategy, || async {
        if user.pins().await?.len() != 3 {
            bail!("not all pins found");
        }
        Ok(())
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
    let ref_attach_id = attachments_manager
        .reference_draft(Box::new(ref_details))
        .await?
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        if attachments_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let attachments = attachments_manager.attachments().await?;
    assert_eq!(attachments.len(), 1);
    let attachment = attachments
        .first()
        .expect("first attachment should be available");
    assert_eq!(attachment.event_id(), ref_attach_id);
    assert_eq!(attachment.type_str(), "ref");

    Ok(())
}
