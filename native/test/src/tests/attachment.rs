use acter::ActerModel;
use anyhow::{bail, Result};
use std::{env, io::Write};
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
async fn attachment_can_redact() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) =
        random_user_with_template("attachment_can_redact", TMPL).await?;
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
    let base_draft = user.image_draft(
        jpg_file.path().to_string_lossy().to_string(),
        "image/jpeg".to_owned(),
    );
    let attachment_id = attachments_manager
        .content_draft(Box::new(base_draft))
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
    assert_eq!(attachment.event_id(), attachment_id);
    assert_eq!(attachment.type_str(), "image");
    let deletable = attachment.can_redact().await?;
    assert!(deletable, "my attachment should be deletable");

    Ok(())
}

#[tokio::test]
async fn attachment_download_media() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) =
        random_user_with_template("attachment_download_media", TMPL).await?;
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
    let base_draft = user.image_draft(
        jpg_file.path().to_string_lossy().to_string(),
        "image/jpeg".to_owned(),
    );
    let attachment_id = attachments_manager
        .content_draft(Box::new(base_draft))
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
    assert_eq!(attachment.event_id(), attachment_id);
    assert_eq!(attachment.type_str(), "image");

    let dir_path = env::temp_dir().to_string_lossy().to_string();
    let downloaded_path = attachment.download_media(None, dir_path).await?;
    assert!(
        downloaded_path.text().is_some(),
        "my attachment should be downloadable"
    );

    let media_path = attachment.media_path(false).await?;
    assert!(
        media_path.text().is_some(),
        "media path should be accessible if it was downloaded once"
    );

    Ok(())
}
