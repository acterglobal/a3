use acter::{api::RoomMessage, new_colorize_builder, ruma_common::OwnedEventId};
use anyhow::{bail, Result};
use core::time::Duration;
use futures::{pin_mut, stream::StreamExt, FutureExt};
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
            } else {
                Ok(())
            }
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
    draft
        .add_slide(Box::new(text_draft.into_news_slide_draft()))
        .await?;
    let event_id = draft.send().await?;
    print!("draft sent event id: {}", event_id);

    Ok(())
}

#[tokio::test]
async fn news_plain_text_test() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, space_id) = random_user_with_random_space("news_plain").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let space_id_str = space_id.to_string();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let space_id = space_id_str.clone();
        async move { client.space(space_id).await }
    })
    .await?;

    let space = user.space(space_id.to_string()).await?;
    let mut draft = space.news_draft()?;
    let text_draft = user.text_plain_draft("This is a simple text".to_owned());
    draft
        .add_slide(Box::new(text_draft.into_news_slide_draft()))
        .await?;
    draft.send().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let space_cl = space.clone();
    Retry::spawn(retry_strategy, move || {
        let inner_space = space_cl.clone();
        async move {
            if inner_space.latest_news_entries(1).await?.len() != 1 {
                bail!("news not found");
            } else {
                Ok(())
            }
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
    let (mut user, space_id) = random_user_with_random_space("news_plain").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let space_id_str = space_id.to_string();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let space_id = space_id_str.clone();
        async move { client.space(space_id).await }
    })
    .await?;

    let space = user.space(space_id.to_string()).await?;
    let mut draft = space.news_draft()?;
    let mut slide_draft = user
        .text_plain_draft("This is a simple text".to_owned())
        .into_news_slide_draft();
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
            } else {
                Ok(())
            }
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
    let (mut user, space_id) = random_user_with_random_space("news_mkd").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let space_id_str = space_id.to_string();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let space_id = space_id_str.clone();
        async move { client.space(space_id).await }
    })
    .await?;

    let space = user.space(space_id.to_string()).await?;
    let mut draft = space.news_draft()?;
    let text_draft = user.text_markdown_draft("## This is a simple text".to_owned());
    draft
        .add_slide(Box::new(text_draft.into_news_slide_draft()))
        .await?;
    draft.send().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let space_cl = space.clone();
    Retry::spawn(retry_strategy, move || {
        let inner_space = space_cl.clone();
        async move {
            if inner_space.latest_news_entries(1).await?.len() != 1 {
                bail!("news not found");
            } else {
                Ok(())
            }
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
    let (mut user, space_id) = random_user_with_random_space("news_jpg").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let space_id_str = space_id.to_string();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let space_id = space_id_str.clone();
        async move { client.space(space_id).await }
    })
    .await?;

    let bytes = include_bytes!("./fixtures/kingfisher.jpg");
    let mut tmp_file = NamedTempFile::new()?;
    tmp_file.as_file_mut().write_all(bytes)?;

    let space = user.space(space_id.to_string()).await?;
    let mut draft = space.news_draft()?;
    let image_draft = user.image_draft(
        tmp_file.path().to_string_lossy().to_string(),
        "image/jpg".to_string(),
    );
    draft
        .add_slide(Box::new(image_draft.into_news_slide_draft()))
        .await?;
    draft.send().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let space_cl = space.clone();
    Retry::spawn(retry_strategy, move || {
        let inner_space = space_cl.clone();
        async move {
            if inner_space.latest_news_entries(1).await?.len() != 1 {
                bail!("news not found");
            } else {
                Ok(())
            }
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
    let (mut user, space_id) = random_user_with_random_space("news_png").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let space_id_str = space_id.to_string();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let space_id = space_id_str.clone();
        async move { client.space(space_id).await }
    })
    .await?;

    let bytes = include_bytes!("./fixtures/PNG_transparency_demonstration_1.png");
    let mut tmp_file = NamedTempFile::new()?;
    tmp_file.as_file_mut().write_all(bytes)?;

    let space = user.space(space_id.to_string()).await?;
    let mut draft = space.news_draft()?;
    let image_draft = user.image_draft(
        tmp_file.path().to_string_lossy().to_string(),
        "image/png".to_string(),
    );
    draft
        .add_slide(Box::new(image_draft.into_news_slide_draft()))
        .await?;
    draft.send().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let space_cl = space.clone();
    Retry::spawn(retry_strategy, move || {
        let inner_space = space_cl.clone();
        async move {
            if inner_space.latest_news_entries(1).await?.len() != 1 {
                bail!("news not found");
            } else {
                Ok(())
            }
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
    let (mut user, space_id) = random_user_with_random_space("news_png").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let space_id_str = space_id.to_string();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let space_id = space_id_str.clone();
        async move { client.space(space_id).await }
    })
    .await?;

    let mut tmp_file = NamedTempFile::new()?;
    tmp_file.as_file_mut().write_all(include_bytes!(
        "./fixtures/PNG_transparency_demonstration_1.png"
    ))?;

    let space = user.space(space_id.to_string()).await?;
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
    draft
        .add_slide(Box::new(image_draft.into_news_slide_draft()))
        .await?;
    draft
        .add_slide(Box::new(markdown_draft.into_news_slide_draft()))
        .await?;
    draft
        .add_slide(Box::new(plain_draft.into_news_slide_draft()))
        .await?;
    draft
        .add_slide(Box::new(video_draft.into_news_slide_draft()))
        .await?;
    draft.send().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let space_cl = space.clone();
    Retry::spawn(retry_strategy, move || {
        let inner_space = space_cl.clone();
        async move {
            if inner_space.latest_news_entries(1).await?.len() != 1 {
                bail!("news not found");
            } else {
                Ok(())
            }
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
    let (mut user, space_id) = random_user_with_random_space("news_like").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let space_id_str = space_id.to_string();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let space_id = space_id_str.clone();
        async move { client.space(space_id).await }
    })
    .await?;

    let bytes = include_bytes!("./fixtures/PNG_transparency_demonstration_1.png");
    let mut tmp_file = NamedTempFile::new()?;
    tmp_file.as_file_mut().write_all(bytes)?;

    let space = user.space(space_id.to_string()).await?;
    let mut draft = space.news_draft()?;
    let image_draft = user.image_draft(
        tmp_file.path().to_string_lossy().to_string(),
        "image/png".to_string(),
    );
    draft
        .add_slide(Box::new(image_draft.into_news_slide_draft()))
        .await?;
    draft.send().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let space_cl = space.clone();
    Retry::spawn(retry_strategy, move || {
        let inner_space = space_cl.clone();
        async move {
            if inner_space.latest_news_entries(1).await?.len() != 1 {
                bail!("news not found");
            } else {
                Ok(())
            }
        }
    })
    .await?;

    let timeline = space.timeline_stream().await;
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let slides = space.latest_news_entries(1).await?;
    let final_entry = slides.first().expect("Item is there");
    let reaction_manager = final_entry.reactions().await?;
    info!("send like reaction ------------------------------------");
    let entry_evt_id = final_entry.event_id().to_string();
    reaction_manager
        .send_reaction(entry_evt_id, "❤️".to_string())
        .await?;

    // text msg may reach via reset action or set action
    let mut i = 10;
    let mut received = None;
    while i > 0 {
        info!("stream loop - {i}");
        if let Some(diff) = stream.next().now_or_never().flatten() {
            info!("stream diff - {}", diff.action());
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    info!("diff pushback - {:?}", value);
                    if let Some(event_id) = match_text_msg(&value, "Hi, everyone") {
                        received = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    info!("diff reset - {:?}", values);
                    for value in values.iter() {
                        if let Some(event_id) = match_text_msg(value, "Hi, everyone") {
                            received = Some(event_id);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if received.is_some() {
                break;
            }
        }
        info!("continue loop");
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    info!("loop finished");

    let my_status = reaction_manager.reacted_by_me().await?;

    // indicates news is reacted with like
    assert!(my_status);

    Ok(())
}

#[tokio::test]
async fn news_unlike_reaction_test() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, space_id) = random_user_with_random_space("news_unlike").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let space_id_str = space_id.to_string();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let space_id = space_id_str.clone();
        async move { client.space(space_id).await }
    })
    .await?;

    let bytes = include_bytes!("./fixtures/PNG_transparency_demonstration_1.png");
    let mut tmp_file = NamedTempFile::new()?;
    tmp_file.as_file_mut().write_all(bytes)?;

    let space = user.space(space_id.to_string()).await?;
    let mut draft = space.news_draft()?;
    let image_draft = user.image_draft(
        tmp_file.path().to_string_lossy().to_string(),
        "image/png".to_string(),
    );
    draft
        .add_slide(Box::new(image_draft.into_news_slide_draft()))
        .await?;
    draft.send().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let space_cl = space.clone();
    Retry::spawn(retry_strategy, move || {
        let inner_space = space_cl.clone();
        async move {
            if inner_space.latest_news_entries(1).await?.len() != 1 {
                bail!("news not found");
            } else {
                Ok(())
            }
        }
    })
    .await?;

    let timeline = space.timeline_stream().await;
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let slides = space.latest_news_entries(1).await?;
    let final_entry = slides.first().expect("Item is there");
    let reaction_manager = final_entry.reactions().await?;
    let entry_evt_id = final_entry.event_id();
    let reaction_evt_id = reaction_manager
        .send_reaction(entry_evt_id.to_string(), "❤️".to_string())
        .await?;

    // text msg may reach via reset action or set action
    let mut i = 10;
    let mut received = None;
    while i > 0 {
        info!("stream loop - {i}");
        if let Some(diff) = stream.next().now_or_never().flatten() {
            info!("stream diff - {}", diff.action());
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    info!("diff pushback - {:?}", value);
                    if let Some(event_id) = match_text_msg(&value, "Hi, everyone") {
                        received = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    info!("diff reset - {:?}", values);
                    for value in values.iter() {
                        if let Some(event_id) = match_text_msg(value, "Hi, everyone") {
                            received = Some(event_id);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if received.is_some() {
                break;
            }
        }
        info!("continue loop");
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    info!("loop finished");

    let my_status = reaction_manager.reacted_by_me().await?;

    // indicates news is reacted with like
    assert_eq!(my_status, true);

    reaction_manager
        .redact_reaction(reaction_evt_id.to_string(), None, None)
        .await?;

    // text msg may reach via reset action or set action
    i = 10;
    received = None;
    while i > 0 {
        info!("stream loop - {i}");
        if let Some(diff) = stream.next().now_or_never().flatten() {
            info!("stream diff - {}", diff.action());
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    info!("diff pushback - {:?}", value);
                    if let Some(event_id) = match_text_msg(&value, "Hi, everyone") {
                        received = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    info!("diff reset - {:?}", values);
                    for value in values.iter() {
                        if let Some(event_id) = match_text_msg(value, "Hi, everyone") {
                            received = Some(event_id);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if received.is_some() {
                break;
            }
        }
        info!("continue loop");
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    info!("loop finished");

    let my_status = reaction_manager.reacted_by_me().await?;

    // indicates news is reacted with like
    assert_eq!(my_status, false);

    Ok(())
}

fn match_text_msg(msg: &RoomMessage, body: &str) -> Option<OwnedEventId> {
    info!("match room msg - {:?}", msg.clone());
    if msg.item_type() == "event" {
        let event_item = msg.event_item().expect("room msg should have event item");
        if let Some(msg_content) = event_item.msg_content() {
            if msg_content.body() == body {
                // exclude the pending msg
                if let Some(event_id) = event_item.evt_id() {
                    return Some(event_id);
                }
            }
        }
    }
    None
}
