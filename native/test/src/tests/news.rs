use crate::utils::{random_user_with_random_space, random_user_with_template};
use acter::new_colorize_builder;
use anyhow::{bail, Result};
use std::io::Write;
use tempfile::NamedTempFile;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

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
    let text_slide = final_entry.get_slide(0).expect("we have a slide");
    assert_eq!(text_slide.type_str(), "text");
    assert!(!text_slide.has_formatted_text());
    assert_eq!(text_slide.text(), "This is a simple text".to_owned());

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
    slide_draft.color(Box::new(new_colorize_builder(
        None,
        Some("rgb(255, 0, 255)".to_owned()),
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
        text_slide
            .colors()
            .map(|e| e.background().as_ref().map(|b| b.to_hex_string()))
            .flatten(),
        Some("#ff00ff".to_owned())
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
    assert!(text_slide.has_formatted_text());
    assert_eq!(
        text_slide.text(),
        "<h2>This is a simple text</h2>\n".to_owned()
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

    let mut tmp_file = NamedTempFile::new()?;
    tmp_file
        .as_file_mut()
        .write_all(include_bytes!("./fixtures/kingfisher.jpg"))?;

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
    assert!(second_slide.has_formatted_text());
    assert_eq!(
        second_slide.text(),
        "<p>This update is <em><strong>reallly important</strong></em></p>\n".to_owned()
    );
    let third_slide = final_entry.get_slide(2).expect("We have plain text slide");
    assert_eq!(third_slide.type_str(), "text");
    assert!(!third_slide.has_formatted_text());
    assert_eq!(third_slide.text(), "Hello Updates!".to_owned());

    let fourth_slide = final_entry.get_slide(3).expect("We have video slide");
    assert_eq!(fourth_slide.type_str(), "video");
    Ok(())
}
