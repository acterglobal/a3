use anyhow::{bail, Result};
use std::io::Write;
use tempfile::NamedTempFile;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

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
    let (user, _sync_state, _engine) = random_user_with_template("news-smoke-", TMPL).await?;

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
    draft.add_text_slide("This is text slide".to_string());
    let event_id = draft.send().await?;
    print!("draft sent event id: {}", event_id);

    Ok(())
}

#[tokio::test]
async fn news_markdown_raw_text_test() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, space_id) = random_user_with_random_space("news-mkd-").await?;
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
    draft.add_text_slide("This is a simple text".to_owned());
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
    assert_eq!(text_slide.has_formatted_text(), false);
    assert_eq!(text_slide.text(), "This is a simple text".to_owned());

    Ok(())
}

#[tokio::test]
async fn news_markdown_text_test() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, space_id) = random_user_with_random_space("news-mkd-").await?;
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
    draft.add_text_slide("## This is a simple text".to_owned());
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
    assert_eq!(text_slide.has_formatted_text(), true);
    assert_eq!(
        text_slide.text(),
        "<h2>This is a simple text</h2>\n".to_owned()
    );

    Ok(())
}

#[tokio::test]
async fn news_jpg_image_with_text_test() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, space_id) = random_user_with_random_space("news-mkd-").await?;
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
    draft
        .add_image_slide(
            "This is a simple text".to_owned(),
            tmp_file.path().as_os_str().to_str().unwrap().to_owned(),
            "image/jpg".to_string(),
            None,
            None,
            None,
            None,
        )
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
    assert_eq!(text_slide.type_str(), "image");
    assert_eq!(text_slide.has_formatted_text(), false);
    assert_eq!(text_slide.text(), "This is a simple text".to_owned());

    Ok(())
}

#[tokio::test]
async fn news_png_image_with_text_test() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, space_id) = random_user_with_random_space("news-mkd-").await?;
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
    draft
        .add_image_slide(
            "This is a simple text".to_owned(),
            tmp_file.path().as_os_str().to_str().unwrap().to_owned(),
            "image/png".to_string(),
            None,
            None,
            None,
            None,
        )
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
    assert_eq!(text_slide.type_str(), "image");
    assert_eq!(text_slide.has_formatted_text(), false);
    assert_eq!(text_slide.text(), "This is a simple text".to_owned());

    Ok(())
}
