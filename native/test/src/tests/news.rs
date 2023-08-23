use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user_with_template;

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
