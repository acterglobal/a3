use acter::{new_colorize_builder, NewsSlideDraft};
use anyhow::{bail, Result};
use core::time::Duration;
use std::io::Write;
use tempfile::NamedTempFile;
use tokio::time::sleep;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};
use tracing::info;

use crate::utils::{random_user_with_random_space, random_user_with_template};

const TMPL: &str = r#"
version = "0.1"
name = "News Smoketest Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }

[objects]
main_space = { type = "space", is-default = true, name = "{{ main.display_name }}'s news test space"}

[objects.example-news-one-image]
type = "news-entry"
slides = [
  { body = "This is the news section. Swipe down for more.", info = { size = 3264047, mimetype = "image/jpeg", thumbnail_info = { w = 400, h = 600, mimetype = "image/jpeg", size = 130511 }, w = 3840, h = 5760, "xyz.amorgan.blurhash" = "TQF=,g?uIo},={X5$c#+V@t2sRjF", thumbnail_url = "mxc://acter.global/aJhqfXrJRWXsFgWFRNlBlpnD" }, msgtype = "m.image", url = "mxc://acter.global/tVLtaQaErMyoXmcCroPZdfNG" }
]

[objects.example-news-two-images]
type = "news-entry"

[[objects.example-news-two-images.slides]]
body = "This is the news section. Swipe down for more."
info = { size = 3264047, mimetype = "image/jpeg", thumbnail_info = { w = 400, h = 600, mimetype = "image/jpeg", size = 130511 }, w = 3840, h = 5760, "xyz.amorgan.blurhash" = "TQF=,g?uIo},={X5$c#+V@t2sRjF", thumbnail_url = "mxc://acter.global/aJhqfXrJRWXsFgWFRNlBlpnD" }
msgtype = "m.image"
url = "mxc://acter.global/tVLtaQaErMyoXmcCroPZdfNG"

[[objects.example-news-two-images.slides]]
body = "This is the news section. Swipe down for more."
info = { size = 3264047, mimetype = "image/jpeg", thumbnail_info = { w = 400, h = 600, mimetype = "image/jpeg", size = 130511 }, w = 3840, h = 5760, "xyz.amorgan.blurhash" = "TQF=,g?uIo},={X5$c#+V@t2sRjF", thumbnail_url = "mxc://acter.global/aJhqfXrJRWXsFgWFRNlBlpnD" }
msgtype = "m.image"
url = "mxc://acter.global/tVLtaQaErMyoXmcCroPZdfNG"

[objects.example-news-three-images]
type = "news-entry"

[[objects.example-news-three-images.slides]]
body = "This is the news section. Swipe down for more."
info = { size = 3264047, mimetype = "image/jpeg", thumbnail_info = { w = 400, h = 600, mimetype = "image/jpeg", size = 130511 }, w = 3840, h = 5760, "xyz.amorgan.blurhash" = "TQF=,g?uIo},={X5$c#+V@t2sRjF", thumbnail_url = "mxc://acter.global/aJhqfXrJRWXsFgWFRNlBlpnD" }
msgtype = "m.image"
url = "mxc://acter.global/tVLtaQaErMyoXmcCroPZdfNG"

[[objects.example-news-three-images.slides]]
body = "This is the news section. Swipe down for more."
info = { size = 3264047, mimetype = "image/jpeg", thumbnail_info = { w = 400, h = 600, mimetype = "image/jpeg", size = 130511 }, w = 3840, h = 5760, "xyz.amorgan.blurhash" = "TQF=,g?uIo},={X5$c#+V@t2sRjF", thumbnail_url = "mxc://acter.global/aJhqfXrJRWXsFgWFRNlBlpnD" }
msgtype = "m.image"
url = "mxc://acter.global/tVLtaQaErMyoXmcCroPZdfNG"

[[objects.example-news-three-images.slides]]
body = "This is the news section. Swipe down for more."
info = { size = 3264047, mimetype = "image/jpeg", thumbnail_info = { w = 400, h = 600, mimetype = "image/jpeg", size = 130511 }, w = 3840, h = 5760, "xyz.amorgan.blurhash" = "TQF=,g?uIo},={X5$c#+V@t2sRjF", thumbnail_url = "mxc://acter.global/aJhqfXrJRWXsFgWFRNlBlpnD" }
msgtype = "m.image"
url = "mxc://acter.global/tVLtaQaErMyoXmcCroPZdfNG"
"#;

#[tokio::test]
async fn news_smoketest() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, _sync_state, _engine) = random_user_with_template("news_smoke", TMPL).await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            if client.latest_news_entries(10).await?.len() != 3 {
                bail!("not all news found");
            }
            Ok(())
        }
    })
    .await?;

    assert_eq!(user.latest_news_entries(10).await?.len(), 3);

    let spaces = user.spaces().await?;
    assert_eq!(spaces.len(), 1);

    let main_space = spaces.first().unwrap();
    assert_eq!(main_space.latest_news_entries(10).await?.len(), 3);

    let mut draft = main_space.news_draft()?;
    let text_draft = user.text_plain_draft("This is text slide".to_string());
    draft.add_slide(Box::new(text_draft.into())).await?;
    let event_id = draft.send().await?;
    print!("draft sent event id: {}", event_id);

    Ok(())
}

#[tokio::test]
async fn news_plain_text_test() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("news_plain").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.space(room_id.to_string()).await }
    })
    .await?;

    let space = user.space(room_id.to_string()).await?;
    let mut draft = space.news_draft()?;
    let text_draft = user.text_plain_draft("This is a simple text".to_owned());
    draft.add_slide(Box::new(text_draft.into())).await?;
    draft.send().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let space_cl = space.clone();
    Retry::spawn(retry_strategy, move || {
        let inner_space = space_cl.clone();
        async move {
            if inner_space.latest_news_entries(1).await?.len() != 1 {
                bail!("news not found");
            }
            Ok(())
        }
    })
    .await?;

    let slides = space.latest_news_entries(1).await?;
    let final_entry = slides.first().expect("Item is there");
    let event_id = final_entry.event_id();
    let text_slide = final_entry.get_slide(0).expect("we have a slide");
    assert_eq!(text_slide.type_str(), "text");
    let msg_content = text_slide.msg_content();
    assert!(msg_content.formatted_body().is_none());
    assert_eq!(msg_content.body(), "This is a simple text".to_owned());

    // also check what the notification will be like
    let notif = user
        .get_notification_item(space.room_id().to_string(), event_id.to_string())
        .await?;

    assert_eq!(notif.title(), space.name().unwrap());
    assert_eq!(notif.push_style().as_str(), "news");
    assert_eq!(
        notif.body().map(|e| e.body()),
        Some("This is a simple text".to_owned())
    );

    Ok(())
}

#[tokio::test]
async fn news_slide_color_test() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("news_plain").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.to_string();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.space(room_id.to_string()).await }
    })
    .await?;

    let space = user.space(room_id.to_string()).await?;
    let mut draft = space.news_draft()?;
    let mut slide_draft: NewsSlideDraft = user
        .text_plain_draft("This is a simple text".to_owned())
        .into();
    slide_draft.color(Box::new(new_colorize_builder(None, Some(0xFF112233))?));
    draft.add_slide(Box::new(slide_draft)).await?;
    draft.send().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let space_cl = space.clone();
    Retry::spawn(retry_strategy, move || {
        let inner_space = space_cl.clone();
        async move {
            if inner_space.latest_news_entries(1).await?.len() != 1 {
                bail!("news not found");
            }
            Ok(())
        }
    })
    .await?;

    let slides = space.latest_news_entries(1).await?;
    let final_entry = slides.first().expect("Item is there");
    let text_slide = final_entry.get_slide(0).expect("we have a slide");
    // no foreground color
    assert_eq!(
        text_slide.colors().map(|e| e.color().is_some()),
        Some(false)
    );
    // the correct background color
    assert_eq!(
        text_slide.colors().and_then(|e| e.background()),
        Some(0xFF112233)
    );

    Ok(())
}

#[tokio::test]
async fn news_markdown_text_test() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("news_mkd").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.space(room_id.to_string()).await }
    })
    .await?;

    let space = user.space(room_id.to_string()).await?;
    let mut draft = space.news_draft()?;
    let text_draft = user.text_markdown_draft("## This is a simple text".to_owned());
    draft.add_slide(Box::new(text_draft.into())).await?;
    draft.send().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let space_cl = space.clone();
    Retry::spawn(retry_strategy, move || {
        let inner_space = space_cl.clone();
        async move {
            if inner_space.latest_news_entries(1).await?.len() != 1 {
                bail!("news not found");
            }
            Ok(())
        }
    })
    .await?;

    let slides = space.latest_news_entries(1).await?;
    let final_entry = slides.first().expect("Item is there");
    let text_slide = final_entry.get_slide(0).expect("we have a slide");
    assert_eq!(text_slide.type_str(), "text");
    let msg_content = text_slide.msg_content();
    assert_eq!(
        msg_content.formatted_body(),
        Some("<h2>This is a simple text</h2>\n".to_owned())
    );

    // also check what the notification will be like
    let notif = user
        .get_notification_item(
            space.room_id().to_string(),
            final_entry.event_id().to_string(),
        )
        .await?;

    assert_eq!(notif.title(), space.name().unwrap());
    assert_eq!(notif.push_style().as_str(), "news");
    assert_eq!(
        notif.body().and_then(|e| e.formatted_body()),
        Some("<h2>This is a simple text</h2>\n".to_owned())
    );
    Ok(())
}

#[tokio::test]
async fn news_jpg_image_with_text_test() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("news_jpg").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.space(room_id.to_string()).await }
    })
    .await?;

    let bytes = include_bytes!("./fixtures/kingfisher.jpg");
    let mut tmp_file = NamedTempFile::new()?;
    tmp_file.as_file_mut().write_all(bytes)?;

    let space = user.space(room_id.to_string()).await?;
    let mut draft = space.news_draft()?;
    let image_draft = user.image_draft(
        tmp_file.path().to_string_lossy().to_string(),
        "image/jpg".to_string(),
    );
    draft.add_slide(Box::new(image_draft.into())).await?;
    draft.send().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let space_cl = space.clone();
    Retry::spawn(retry_strategy, move || {
        let inner_space = space_cl.clone();
        async move {
            if inner_space.latest_news_entries(1).await?.len() != 1 {
                bail!("news not found");
            }
            Ok(())
        }
    })
    .await?;

    let slides = space.latest_news_entries(1).await?;
    let final_entry = slides.first().expect("Item is there");
    let image_slide = final_entry.get_slide(0).expect("we have a slide");
    assert_eq!(image_slide.type_str(), "image");

    // also check what the notification will be like
    let notif = user
        .get_notification_item(
            space.room_id().to_string(),
            final_entry.event_id().to_string(),
        )
        .await?;

    assert_eq!(notif.title(), space.name().unwrap());
    assert!(notif.body().is_none());
    assert_eq!(notif.push_style().as_str(), "news");
    assert!(notif.has_image());
    let _image_data = notif.image().await?;

    Ok(())
}

#[tokio::test]
async fn news_png_image_with_text_test() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("news_png").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.space(room_id.to_string()).await }
    })
    .await?;

    let bytes = include_bytes!("./fixtures/PNG_transparency_demonstration_1.png");
    let mut tmp_file = NamedTempFile::new()?;
    tmp_file.as_file_mut().write_all(bytes)?;

    let space = user.space(room_id.to_string()).await?;
    let mut draft = space.news_draft()?;
    let image_draft = user.image_draft(
        tmp_file.path().to_string_lossy().to_string(),
        "image/png".to_string(),
    );
    draft.add_slide(Box::new(image_draft.into())).await?;
    draft.send().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let space_cl = space.clone();
    Retry::spawn(retry_strategy, move || {
        let inner_space = space_cl.clone();
        async move {
            if inner_space.latest_news_entries(1).await?.len() != 1 {
                bail!("news not found");
            }
            Ok(())
        }
    })
    .await?;

    let slides = space.latest_news_entries(1).await?;
    let final_entry = slides.first().expect("Item is there");
    let image_slide = final_entry.get_slide(0).expect("we have a slide");
    assert_eq!(image_slide.type_str(), "image");

    Ok(())
}

#[tokio::test]
async fn news_multiple_slide_test() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("news_png").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.space(room_id.to_string()).await }
    })
    .await?;

    let mut tmp_file = NamedTempFile::new()?;
    tmp_file.as_file_mut().write_all(include_bytes!(
        "./fixtures/PNG_transparency_demonstration_1.png"
    ))?;

    let space = user.space(room_id.to_string()).await?;
    let mut draft = space.news_draft()?;
    let image_draft = user.image_draft(
        tmp_file.path().to_string_lossy().to_string(),
        "image/png".to_string(),
    );
    let markdown_draft =
        user.text_markdown_draft("This update is ***reallly important***".to_owned());

    let plain_draft = user.text_plain_draft("Hello Updates!".to_owned());

    let mut vid_file = NamedTempFile::new()?;
    vid_file
        .as_file_mut()
        .write_all(include_bytes!("./fixtures/big_buck_bunny.mp4"))?;

    let video_draft = user.video_draft(
        vid_file.path().to_string_lossy().to_string(),
        "video/mp4".to_string(),
    );

    // we add three slides
    draft.add_slide(Box::new(image_draft.into())).await?;
    draft.add_slide(Box::new(markdown_draft.into())).await?;
    draft.add_slide(Box::new(plain_draft.into())).await?;
    draft.add_slide(Box::new(video_draft.into())).await?;
    draft.send().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let space_cl = space.clone();
    Retry::spawn(retry_strategy, move || {
        let inner_space = space_cl.clone();
        async move {
            if inner_space.latest_news_entries(1).await?.len() != 1 {
                bail!("news not found");
            }
            Ok(())
        }
    })
    .await?;

    let slides = space.latest_news_entries(1).await?;
    let final_entry = slides.first().expect("Item is there");
    // We have exactly four slides
    assert_eq!(4, final_entry.slides().len());
    let first_slide = final_entry.get_slide(0).expect("We have image slide");
    assert_eq!(first_slide.type_str(), "image");
    let second_slide = final_entry
        .get_slide(1)
        .expect("We have markdown text slide");
    assert_eq!(second_slide.type_str(), "text");
    let msg_content = second_slide.msg_content();
    assert_eq!(
        msg_content.formatted_body(),
        Some("<p>This update is <em><strong>reallly important</strong></em></p>\n".to_owned())
    );
    let third_slide = final_entry.get_slide(2).expect("We have plain text slide");
    assert_eq!(third_slide.type_str(), "text");
    let msg_content = third_slide.msg_content();
    assert!(msg_content.formatted_body().is_none());
    assert_eq!(msg_content.body(), "Hello Updates!".to_owned());

    let fourth_slide = final_entry.get_slide(3).expect("We have video slide");
    assert_eq!(fourth_slide.type_str(), "video");
    Ok(())
}

#[tokio::test]
async fn news_like_reaction_test() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("news_like").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.space(room_id.to_string()).await }
    })
    .await?;

    let bytes = include_bytes!("./fixtures/PNG_transparency_demonstration_1.png");
    let mut tmp_file = NamedTempFile::new()?;
    tmp_file.as_file_mut().write_all(bytes)?;

    let space = user.space(room_id.to_string()).await?;
    let mut draft = space.news_draft()?;
    let image_draft = user.image_draft(
        tmp_file.path().to_string_lossy().to_string(),
        "image/png".to_string(),
    );
    draft.add_slide(Box::new(image_draft.into())).await?;
    draft.send().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let space_cl = space.clone();
    Retry::spawn(retry_strategy, move || {
        let inner_space = space_cl.clone();
        async move {
            if inner_space.latest_news_entries(1).await?.len() != 1 {
                bail!("news not found");
            }
            Ok(())
        }
    })
    .await?;

    let slides = space.latest_news_entries(1).await?;
    let final_entry = slides.first().expect("Item is there");
    let reaction_manager = final_entry.reactions().await?;
    let mut reaction_updates = reaction_manager.subscribe();
    assert!(!reaction_manager.liked_by_me());
    info!("send like reaction ------------------------------------");
    reaction_manager.send_like().await?;

    // text msg may reach via reset action or set action
    let mut i = 10;
    let mut found = false;
    while i > 0 {
        info!("stream loop - {i}");
        if reaction_updates.try_recv().is_ok() {
            found = true;
            break;
        }
        info!("continue loop");
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    info!("loop finished");
    assert!(found, "Even after 10 seconds, send_like not received");

    let reaction_manager = reaction_manager.reload().await?;
    info!("stats: {:#?}", reaction_manager.stats());

    // assert!(reaction_manager.reacted_by_me());
    assert!(reaction_manager.liked_by_me());
    assert_eq!(reaction_manager.likes_count(), 1);

    // redacting the like

    reaction_manager.redact_like(None, None).await?;

    // text msg may reach via reset action or set action
    i = 10;
    found = false;
    while i > 0 {
        info!("stream loop - {i}");
        if reaction_updates.try_recv().is_ok() {
            found = true;
            break;
        }
        info!("continue loop");
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    info!("loop finished");
    assert!(found, "Even after 10 seconds, redact_like not received");

    let reaction_manager = reaction_manager.reload().await?;

    assert!(!reaction_manager.reacted_by_me());
    assert!(!reaction_manager.liked_by_me());
    assert_eq!(reaction_manager.likes_count(), 0);

    Ok(())
}
