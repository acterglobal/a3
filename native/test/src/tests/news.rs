use acter::{new_colorize_builder, new_obj_ref_builder, NewsSlideDraft};
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

use crate::utils::{
    random_user_with_random_space, random_user_with_template, random_users_with_random_space,
};

const TMPL: &str = r#"
version = "0.1"
name = "News Smoketest Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }

[objects]
main_space = { type = "space", is-default = true, name = "{{ main.display_name }}’s news test space" }

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
    let (user, sync_state, _engine) = random_user_with_template("news_smoke", TMPL).await?;
    sync_state.await_has_synced_history().await?;

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

    let main_space = spaces.first().expect("main space should be available");
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
    let second_news = slides.first().expect("Item is there");
    let _event_id = second_news.event_id();
    let text_slide = second_news.get_slide(0).expect("we have a slide");
    assert_eq!(text_slide.type_str(), "text");
    let msg_content = text_slide.msg_content();
    assert!(msg_content.formatted_body().is_none());
    assert_eq!(msg_content.body(), "This is a simple text");

    // FIXME: notifications need to be checked against a secondary client..
    // // also check what the notification will be like
    // let notif = user
    //     .get_notification_item(space.room_id().to_string(), event_id.to_string())
    //     .await?;

    // assert_eq!(Some(notif.title()), space.name());
    // assert_eq!(notif.push_style().as_str(), "news");
    // assert_eq!(
    //     notif.body().map(|e| e.body()).as_deref(),
    //     Some("This is a simple text")
    // );

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
    slide_draft.color(Box::new(new_colorize_builder(
        None,
        Some(0xFF112233),
        Some(0xFF112233),
    )?));
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
    // the correct link color
    assert_eq!(text_slide.colors().and_then(|e| e.link()), Some(0xFF112233));

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
        msg_content.formatted_body().as_deref(),
        Some("<h2>This is a simple text</h2>\n")
    );

    // FIXME: notifications need to be checked against a secondary client..
    // // also check what the notification will be like
    // let notif = user
    //     .get_notification_item(
    //         space.room_id().to_string(),
    //         final_entry.event_id().to_string(),
    //     )
    //     .await?;

    // assert_eq!(Some(notif.title()), space.name());
    // assert_eq!(notif.push_style().as_str(), "news");
    // assert_eq!(
    //     notif.body().and_then(|e| e.formatted_body()).as_deref(),
    //     Some("<h2>This is a simple text</h2>\n")
    // );
    Ok(())
}

const PINS_TMPL: &str = r#"
version = "0.1"
name = "Pins Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }

[objects]
main_space = { type = "space", is-default = true, name = "{{ main.display_name }}’s pins test space" }

[objects.acter-website-pin]
type = "pin"
title = "Acter Website"
url = "https://acter.global"

"#;

#[tokio::test]
async fn news_markdown_text_with_reference_test() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, state_sync, _e) =
        random_user_with_template("news_with_reference", PINS_TMPL).await?;
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            if client.pins().await?.len() != 1 {
                bail!("not all pins found");
            }
            Ok(())
        }
    })
    .await?;

    let spaces = user.spaces().await?;
    assert_eq!(spaces.len(), 1);
    let space = spaces.first().expect("we have the space");
    let pins = user.pins().await?;
    let pin = pins.first().expect("We have a pin");
    let mut draft = space.news_draft()?;
    let mut text_draft: NewsSlideDraft = user
        .text_markdown_draft("## This is a simple text".to_owned())
        .into();
    let ref_details = pin.ref_details().await?;
    let obj_ref_builder = new_obj_ref_builder(None, Box::new(ref_details))?;
    text_draft.add_reference(Box::new(obj_ref_builder));
    draft.add_slide(Box::new(text_draft)).await?;
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
        msg_content.formatted_body().as_deref(),
        Some("<h2>This is a simple text</h2>\n")
    );

    // FIXME: notifications need to be checked against a secondary client..
    // // also check what the notification will be like
    // let notif = user
    //     .get_notification_item(
    //         space.room_id().to_string(),
    //         final_entry.event_id().to_string(),
    //     )
    //     .await?;

    // assert_eq!(Some(notif.title()), space.name());
    // assert_eq!(notif.push_style().as_str(), "news");
    // assert_eq!(
    //     notif.body().and_then(|e| e.formatted_body()).as_deref(),
    //     Some("<h2>This is a simple text</h2>\n")
    // );
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

    // FIXME: notifications need to be checked against a secondary client..
    // // also check what the notification will be like
    // let notif = user
    //     .get_notification_item(
    //         space.room_id().to_string(),
    //         final_entry.event_id().to_string(),
    //     )
    //     .await?;

    // assert_eq!(Some(notif.title()), space.name());
    // assert!(notif.body().is_none());
    // assert_eq!(notif.push_style().as_str(), "news");
    // assert!(notif.has_image());
    // let _image_data = notif.image().await?;

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
    let formatted_body = msg_content.formatted_body();
    assert_eq!(
        formatted_body.as_deref(),
        Some("This update is <em><strong>reallly important</strong></em>")
    );
    let third_slide = final_entry.get_slide(2).expect("We have plain text slide");
    assert_eq!(third_slide.type_str(), "text");
    let msg_content = third_slide.msg_content();
    assert!(msg_content.formatted_body().is_none());
    assert_eq!(msg_content.body(), "Hello Updates!");

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

#[tokio::test]
async fn news_read_receipt_test() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut users, room_id) = random_users_with_random_space("news_views", 4).await?;
    let mut user = users.remove(0);
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy.clone(), move || {
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

    let space_cl = space.clone();
    Retry::spawn(retry_strategy.clone(), move || {
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
    let final_entry = slides.first().expect("first slide should be available");
    let main_receipts_manager = final_entry.read_receipts().await?;
    assert_eq!(main_receipts_manager.read_count(), 0);

    for (idx, mut user) in users.into_iter().enumerate() {
        let state_sync = user.start_sync();
        state_sync.await_has_synced_history().await?;
        let uidx = idx as u32;
        let subscriber = main_receipts_manager.subscribe();

        let fetcher_client = user.clone();
        let target_id = room_id.clone();
        Retry::spawn(retry_strategy.clone(), move || {
            let client = fetcher_client.clone();
            let room_id = target_id.clone();
            async move { client.space(room_id.to_string()).await }
        })
        .await?;

        let space = user.space(room_id.to_string()).await?;

        let space_cl = space.clone();
        Retry::spawn(retry_strategy.clone(), move || {
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
        let news_entry = slides.first().expect("first slide should be available");

        let local_receipts_manager = news_entry.read_receipts().await?;
        assert_eq!(local_receipts_manager.read_count(), uidx);
        local_receipts_manager.announce_read().await?;

        Retry::spawn(retry_strategy.clone(), || async {
            if subscriber.is_empty() {
                bail!("not been alerted to reload");
            }
            Ok(())
        })
        .await?;

        let receipts_manager = main_receipts_manager.clone();
        Retry::spawn(retry_strategy.clone(), move || {
            let receipts_manager = receipts_manager.clone();
            async move {
                let new_receipts_manager = receipts_manager.reload().await?;
                if new_receipts_manager.read_count() != uidx + 1 {
                    bail!("news read receipt after {uidx} not found");
                }
                Ok(())
            }
        })
        .await?;
    }

    Ok(())
}

#[tokio::test]
async fn multi_news_read_receipt_test() -> Result<()> {
    // In this test we create two news entries, an older and a newer one
    // then sync up the several users and have them check off the newer
    // and then the older one as read by them and expect the view count
    // to increase as such
    // Note: this is incompatible with the way that matrix thinks about
    //       read receipts - latest marked means all before are marked -
    //       and ensures that our implementation properly does though.
    let _ = env_logger::try_init();
    let (mut users, room_id) = random_users_with_random_space("news_views", 4).await?;
    let mut user = users.remove(0);
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.space(room_id.to_string()).await }
    })
    .await?;

    let space = user.space(room_id.to_string()).await?;
    let mut draft = space.news_draft()?;
    let text_draft = user.text_markdown_draft("## This is a simple text".to_owned());
    draft.add_slide(Box::new(text_draft.into())).await?;
    let first_news_id = draft.send().await?;

    let mut draft = space.news_draft()?;
    let text_draft = user.text_markdown_draft("## This is a second news".to_owned());
    draft.add_slide(Box::new(text_draft.into())).await?;
    let second_news_id = draft.send().await?;

    let space_cl = space.clone();
    let slides = Retry::spawn(retry_strategy.clone(), move || {
        let inner_space = space_cl.clone();
        async move {
            let news_entries = inner_space.latest_news_entries(2).await?;
            if news_entries.len() != 2 {
                bail!("news not found");
            }
            Ok(news_entries)
        }
    })
    .await?;
    let mut slides_iter = slides.into_iter();
    let newest_slide = slides_iter
        .next()
        .expect("newest slide should be available");
    assert_eq!(newest_slide.event_id(), second_news_id);
    let older_slide = slides_iter.next().expect("older slide should be available");
    assert_eq!(older_slide.event_id(), first_news_id);

    let newest_slide_rr_manager = newest_slide.read_receipts().await?;
    assert_eq!(newest_slide_rr_manager.read_count(), 0);
    let older_slide_rr_manager = older_slide.read_receipts().await?;
    assert_eq!(older_slide_rr_manager.read_count(), 0);

    for (idx, mut user) in users.into_iter().enumerate() {
        let state_sync = user.start_sync();
        state_sync.await_has_synced_history().await?;
        let uidx = idx as u32;
        let newest_subscriber = newest_slide_rr_manager.subscribe();
        let older_subscriber = older_slide_rr_manager.subscribe();

        let fetcher_client = user.clone();
        let target_id = room_id.clone();
        Retry::spawn(retry_strategy.clone(), move || {
            let client = fetcher_client.clone();
            let room_id = target_id.clone();
            async move { client.space(room_id.to_string()).await }
        })
        .await?;

        let space = user.space(room_id.to_string()).await?;

        let space_cl = space.clone();
        let mut slides = Retry::spawn(retry_strategy.clone(), move || {
            let inner_space = space_cl.clone();
            async move {
                let news_entries = inner_space.latest_news_entries(2).await?;
                if news_entries.len() != 2 {
                    bail!("news not found");
                }
                Ok(news_entries)
            }
        })
        .await?
        .into_iter();

        let newest_entry = slides.next().expect("newest slide should be available");
        assert_eq!(newest_entry.event_id(), second_news_id);

        let local_receipts_manager = newest_entry.read_receipts().await?;
        assert_eq!(local_receipts_manager.read_count(), uidx);
        local_receipts_manager.announce_read().await?;

        Retry::spawn(retry_strategy.clone(), || async {
            if newest_subscriber.is_empty() {
                bail!("newer: not been alerted to reload");
            }
            Ok(())
        })
        .await?;

        assert!(older_subscriber.is_empty());

        let receipts_manager = newest_slide_rr_manager.clone();
        Retry::spawn(retry_strategy.clone(), move || {
            let receipts_manager = receipts_manager.clone();
            async move {
                let new_receipts_manager = receipts_manager.reload().await?;
                let read_count = new_receipts_manager.read_count();
                if read_count != uidx + 1 {
                    bail!("newer: news read receipt {read_count} wrong at {uidx} ");
                }
                Ok(())
            }
        })
        .await?;

        // now the user is looking at the older slide

        let older_entry = slides.next().expect("older slide should be available");
        assert_eq!(older_entry.event_id(), first_news_id);

        let local_receipts_manager = older_entry.read_receipts().await?;
        assert_eq!(local_receipts_manager.read_count(), uidx);
        local_receipts_manager.announce_read().await?;

        Retry::spawn(retry_strategy.clone(), || async {
            if older_subscriber.is_empty() {
                bail!("older: not been alerted to reload");
            }
            Ok(())
        })
        .await?;

        let receipts_manager = older_slide_rr_manager.clone();
        Retry::spawn(retry_strategy.clone(), move || {
            let receipts_manager = receipts_manager.clone();
            async move {
                let new_receipts_manager = receipts_manager.reload().await?;
                let read_count = new_receipts_manager.read_count();
                if read_count != uidx + 1 {
                    bail!("older: news read receipt {read_count} wrong at {uidx} ");
                }
                Ok(())
            }
        })
        .await?;
    }

    Ok(())
}
