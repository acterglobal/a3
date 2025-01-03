use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_users_with_random_space_under_template;

const TMPL: &str = r#"
version = "0.1"
name = "News Notifications Setup Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }
space = { type = "space", is-default = true, required = true, description = "The main user" }

[objects.example-news-one-image]
type = "news-entry"
slides = [
  { body = "This is the news section. Swipe down for more.", info = { size = 3264047, mimetype = "image/jpeg", thumbnail_info = { w = 400, h = 600, mimetype = "image/jpeg", size = 130511 }, w = 3840, h = 5760, "xyz.amorgan.blurhash" = "TQF=,g?uIo},={X5$c#+V@t2sRjF", thumbnail_url = "mxc://acter.global/aJhqfXrJRWXsFgWFRNlBlpnD" }, msgtype = "m.image", url = "mxc://acter.global/tVLtaQaErMyoXmcCroPZdfNG" }
]

[objects.acter-event-1]
type = "calendar-event"
title = "Onboarding on Acter"
utc_start = "{{ future(add_mins=1).as_rfc3339 }}"
utc_end = "{{ future(add_mins=60).as_rfc3339 }}"

[objects.acter-website-pin]
type = "pin"
title = "Acter Website"
url = "https://acter.global"

[objects.acter-source-pin]
type = "pin"
title = "Acter Source Code"
url = "https://github.com/acterglobal/a3"

"#;

#[tokio::test]
async fn comment_on_news() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("cOnboost", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = second_user.clone();
    let news_entry = Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            let news_entries = client.latest_news_entries(1).await?;
            if news_entries.len() != 1 {
                bail!("news entries not found found");
            }
            Ok(news_entries[0].clone())
        }
    })
    .await?;

    // ensure we are expected to see these notifications
    let _ = first
        .notification_settings()
        .await?
        .object_push_subscription_status_str(news_entry.event_id().to_string(), None)
        .await?;

    let comments = news_entry.comments().await?;
    let mut draft = comments.comment_draft()?;
    draft.content_text("this is great".to_owned());
    let notification_ev = draft.send().await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    Ok(())
}
