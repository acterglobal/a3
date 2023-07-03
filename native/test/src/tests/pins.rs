use acter::{testing::wait_for, ActerModel};
use anyhow::{bail, Result};
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
main_space = { type = "space", is-default = true, name = "{{ main.display_name }}'s pins test space"}

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
    let (user, _sync_state, _engine) = random_user_with_template("pins-smoke-", TMPL).await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            if client.pins().await?.len() != 3 {
                bail!("not all pins found");
            } else {
                Ok(())
            }
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
    let (user, _sync_state, _engine) = random_user_with_template("pins-comments--", TMPL).await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            if client.pins().await?.len() != 3 {
                bail!("not all pins found");
            } else {
                Ok(())
            }
        }
    })
    .await?;

    let pin = user
        .pins()
        .await?
        .into_iter()
        .find(|p| !p.is_link())
        .expect("we've created one non-link pin");

    // START actual comment on pin

    let comments_manager = pin.comments().await?;
    assert!(!comments_manager.stats().has_comments());

    // ---- let's make a comment

    let comments_listener = comments_manager.subscribe();
    let comment_1_id = comments_manager
        .comment_draft()?
        .content_text("I updated the pin".to_owned())
        .send()
        .await?;

    assert!(
        wait_for(move || {
            let mut comments_listener = comments_listener.clone();
            async move {
                if let Ok(t) = comments_listener.try_recv() {
                    Ok(Some(t))
                } else {
                    Ok(None)
                }
            }
        })
        .await?
        .is_some(),
        "Didn't receive any update on the list for the first event"
    );

    let comments = comments_manager.comments().await?;
    assert_eq!(comments.len(), 1);
    assert_eq!(comments[0].event_id(), comment_1_id);
    assert_eq!(comments[0].content().body, "I updated the pin".to_owned());

    Ok(())
}

#[tokio::test]
async fn pin_attachments() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, _sync_state, _engine) =
        random_user_with_template("pins-attachments--", TMPL).await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            if client.pins().await?.len() != 3 {
                bail!("not all pins found");
            } else {
                Ok(())
            }
        }
    })
    .await?;

    let pin = user
        .pins()
        .await?
        .into_iter()
        .find(|p| !p.is_link())
        .expect("we've created one non-link pin");

    // START actual attachment on pin

    let attachments_manager = pin.attachments().await?;
    assert!(!attachments_manager.stats().has_attachments());

    // ---- let's make a attachment

    let attachments_listener = attachments_manager.subscribe();
    let attachment_1_id = attachments_manager
        .image_attachment_draft(
            "acter logo".to_owned(),
            "https://raw.githubusercontent.com/acterglobal/a3/main/app/assets/icon/acter-logo.svg"
                .to_owned(),
            None,
            None,
            None,
            None,
            None,
        )?
        .send()
        .await?;

    assert!(
        wait_for(move || {
            let mut attachments_listener = attachments_listener.clone();
            async move {
                if let Ok(t) = attachments_listener.try_recv() {
                    Ok(Some(t))
                } else {
                    Ok(None)
                }
            }
        })
        .await?
        .is_some(),
        "Didn't receive any update on the list for the first event"
    );

    let attachments = attachments_manager.attachments().await?;
    assert_eq!(attachments.len(), 1);
    let attachment = attachments.first().unwrap();
    assert_eq!(attachment.event_id(), attachment_1_id);
    assert_eq!(attachment.type_str(), "image");
    assert_eq!(attachment.image_desc().unwrap().name(), "acter logo");
    assert_eq!(
        attachment.image_desc().unwrap().source().url(),
        "https://raw.githubusercontent.com/acterglobal/a3/main/app/assets/icon/acter-logo.svg"
    );

    // go for the second

    let attachments_listener = attachments_manager.subscribe();
    let attachment_2_id = attachments_manager
        .file_attachment_draft(
            "effektio whitepaper".to_owned(),
            "mxc://acter.global/tVLtaQaErMyoXmcCroPZdfNG".to_owned(),
            None,
            None,
        )?
        .send()
        .await?;

    assert!(
        wait_for(move || {
            let mut attachments_listener = attachments_listener.clone();
            async move {
                if let Ok(t) = attachments_listener.try_recv() {
                    Ok(Some(t))
                } else {
                    Ok(None)
                }
            }
        })
        .await?
        .is_some(),
        "Didn't receive any update on the list for the first event"
    );

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
