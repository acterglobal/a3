use acter::api::{new_join_rule_builder, new_space_settings_builder};
use acter_core::statics::KEYS;
use anyhow::{bail, Result};
use matrix_sdk_base::ruma::events::{
    room::join_rules::{AllowRule, JoinRule, Restricted},
    StateEventType,
};
use tokio::sync::broadcast::error::TryRecvError;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user_with_template;

const THREE_SPACES_TMPL: &str = r#"
version = "0.1"
name = "Smoketest Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }

[objects.main_space]
type = "space"
name = "{{ main.display_name }}’s main test space"

[objects.second_space]
type = "space"
name = "{{ main.display_name }}’s first test space"

[objects.third_space]
type = "space"
name = "{{ main.display_name }}’s second test space"

[objects.main_space_pin]
type = "pin"
in = "main_space"
title = "Acter Website"
url = "https://acter.global"

[objects.main_space_news]
type = "news-entry"
in = "main_space"
slides = []

[objects.second_space_pin]
type = "pin"
in = "second_space"
title = "Acter Website"
url = "https://acter.global"

[objects.second_space_news]
type = "news-entry"
in = "second_space"
slides = []

[objects.third_space_pin]
type = "pin"
in = "third_space"
title = "Acter Website"
url = "https://acter.global"


[objects.third_space_news]
type = "news-entry"
in = "third_space"
slides = []

"#;

#[tokio::test]
async fn leaving_spaces() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) =
        random_user_with_template("leaving_spaces", THREE_SPACES_TMPL).await?;
    sync_state.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.spaces().await?.len() != 3 {
                bail!("not all spaces found");
            }
            Ok(())
        }
    })
    .await?;

    let mut spaces = user.spaces().await?;

    assert_eq!(spaces.len(), 3);

    // make sure all pins are synced
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.pins().await?.len() != 3 {
                bail!("not all pins found");
            }
            if client.latest_news_entries(10).await?.len() != 3 {
                bail!("not all news found");
            }
            Ok(())
        }
    })
    .await?;

    let first = spaces.pop().unwrap();
    let second = spaces.pop().unwrap();
    let last = spaces.pop().unwrap();

    let mut first_listener = user.subscribe(first.room_id().to_string());
    let mut news_listener = user.subscribe(KEYS::NEWS.to_string());
    let mut second_listener = user.subscribe(second.room_id().to_string());
    let mut last_listener = user.subscribe(last.room_id().to_string());

    assert!(news_listener.is_empty(), "News already has items");

    first.leave().await?;
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.spaces().await?.len() != 2 {
                bail!("not the right number of spaces found");
            }
            Ok(())
        }
    })
    .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if first_listener.is_empty() {
            // not yet.
            bail!("First still empty");
        }
        Ok(())
    })
    .await?;
    Retry::spawn(retry_strategy.clone(), || async {
        if news_listener.is_empty() {
            // not yet.
            bail!("News listener didn’t react");
        }
        Ok(())
    })
    .await?;

    // the objects have been reduced
    assert_eq!(user.pins().await?.len(), 2);
    assert_eq!(user.latest_news_entries(10).await?.len(), 2);

    assert!(first_listener.try_recv().is_ok());
    assert!(news_listener.try_recv().is_ok());
    assert_eq!(second_listener.try_recv(), Err(TryRecvError::Empty));
    assert_eq!(last_listener.try_recv(), Err(TryRecvError::Empty));

    second.leave().await?;
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.spaces().await?.len() != 1 {
                bail!("not the right number of spaces found");
            }
            Ok(())
        }
    })
    .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if second_listener.is_empty() {
            // this was empty, try again
            bail!("second listener still empty");
        }
        Ok(())
    })
    .await?;
    Retry::spawn(retry_strategy.clone(), || async {
        if news_listener.is_empty() {
            // not yet.
            bail!("News listener didn’t react");
        }
        Ok(())
    })
    .await?;

    // the objects have been reduced again
    assert_eq!(user.pins().await?.len(), 1);
    assert_eq!(user.latest_news_entries(10).await?.len(), 1);

    assert!(news_listener.try_recv().is_ok());
    assert_eq!(first_listener.try_recv(), Err(TryRecvError::Empty));
    assert!(second_listener.try_recv().is_ok());
    assert_eq!(last_listener.try_recv(), Err(TryRecvError::Empty));

    Ok(())
}

const TMPL: &str = r#"
version = "0.1"
name = "Smoketest Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }

[objects.main_space]
type = "space"
name = "{{ main.display_name }}’s main test space"
"#;

#[tokio::test]
async fn create_subspace() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) = random_user_with_template("subspace_create", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.spaces().await?.len() != 1 {
                bail!("not all spaces found");
            }
            Ok(())
        }
    })
    .await?;

    let mut spaces = user.spaces().await?;

    assert_eq!(spaces.len(), 1);

    let first = spaces.pop().unwrap();

    let mut cfg = new_space_settings_builder();
    cfg.set_name("subspace".to_owned());
    cfg.set_parent(first.room_id().to_string());

    let settings = cfg.build()?;
    let subspace_id = user.create_acter_space(Box::new(settings)).await?;

    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.spaces().await?.len() != 2 {
                bail!("not the right number of spaces found");
            }
            Ok(())
        }
    })
    .await?;

    let space = user.space(subspace_id.to_string()).await?;
    let space_parent = Retry::spawn(retry_strategy.clone(), move || {
        let space = space.clone();
        async move {
            let space_relations = space.space_relations().await?;
            let Some(space_parent) = space_relations.main_parent() else {
                bail!("space misses main parent");
            };
            Ok(space_parent)
        }
    })
    .await?;

    assert_eq!(space_parent.room_id(), first.room_id());

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);

    Retry::spawn(retry_strategy.clone(), || async {
        if user.spaces().await?.is_empty() {
            bail!("still no spaces found");
        }
        Ok(())
    })
    .await?;

    Ok(())
}

#[tokio::test]
async fn change_subspace_join_rule() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) = random_user_with_template("subspace_create", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.spaces().await?.len() != 1 {
                bail!("not all spaces found");
            }
            Ok(())
        }
    })
    .await?;

    let mut spaces = user.spaces().await?;

    assert_eq!(spaces.len(), 1);

    let first = spaces.pop().unwrap();

    let mut cfg = new_space_settings_builder();
    cfg.set_name("subspace".to_owned());
    cfg.set_parent(first.room_id().to_string());

    let settings = cfg.build()?;
    let subspace_id = user.create_acter_space(Box::new(settings)).await?;

    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.spaces().await?.len() != 2 {
                bail!("not the right number of spaces found");
            }
            Ok(())
        }
    })
    .await?;

    let space = user.space(subspace_id.to_string()).await?;
    let space_parent = Retry::spawn(retry_strategy.clone(), || {
        let space = space.clone();
        async move {
            let space_relations = space.space_relations().await?;
            let Some(space_parent) = space_relations.main_parent() else {
                bail!("space misses main parent");
            };
            Ok(space_parent)
        }
    })
    .await?;
    assert_eq!(space_parent.room_id(), first.room_id());
    assert_eq!(space.join_rule_str(), "restricted");

    let mut update = new_join_rule_builder();
    update.join_rule("private".to_string());

    space.set_join_rule(Box::new(update)).await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);

    Retry::spawn(retry_strategy.clone(), || async {
        let space = user.space(subspace_id.to_string()).await?;
        if space.join_rule_str() != "private" {
            bail!("update did not occur");
        }
        Ok(())
    })
    .await?;

    // let’s move it back to restricted
    assert_eq!(space.join_rule_str(), "private");
    let join_rule = space.join_rule();

    assert!(matches!(join_rule, JoinRule::Private));

    let mut update = new_join_rule_builder();
    update.join_rule("restricted".to_string());
    update.add_room(space_parent.room_id().to_string());

    space.set_join_rule(Box::new(update)).await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);

    Retry::spawn(retry_strategy.clone(), || async {
        let space = user.space(subspace_id.to_string()).await?;
        if space.join_rule_str() != "restricted" {
            bail!("update did not occur");
        }
        Ok(())
    })
    .await?;

    let space = user.space(subspace_id.to_string()).await?;
    let join_rule = space.join_rule();
    let target = JoinRule::Restricted(Restricted::new(vec![AllowRule::room_membership(
        space_parent.room_id(),
    )]));

    if join_rule != target {
        bail!(
            "Join rule is incorrect: {:?}, expected {:?}",
            join_rule,
            target
        );
    }

    Ok(())
}

#[tokio::test]
async fn update_name() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) = random_user_with_template("space_update_name", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.spaces().await?.len() != 1 {
                bail!("not all spaces found");
            }
            Ok(())
        }
    })
    .await?;

    let mut spaces = user.spaces().await?;

    assert_eq!(spaces.len(), 1);

    let space = spaces.pop().unwrap();
    let listener = space.subscribe();
    let space_id = space.room_id().to_string();

    // wait for sync to receive permission
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let space_clone = space.clone();
    let user_id = user.user_id()?;
    Retry::spawn(retry_strategy.clone(), move || {
        let space = space_clone.clone();
        let uid = user_id.clone();
        async move {
            let permitted = space
                .can_user_send_state(&uid, StateEventType::RoomName)
                .await?;
            if !permitted {
                bail!("space name change was not permitted");
            }
            Ok(())
        }
    })
    .await?;

    // set name

    let _event_id = space.set_name("New Name".to_owned()).await?;

    let fetcher_client = user.clone();
    let space_id_clone = space_id.clone();
    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        let space_id = space_id_clone.clone();
        async move {
            let space = client.space(space_id).await?;
            if space.name() != Some("New Name".to_owned()) {
                bail!("Name not set");
            }
            Ok(())
        }
    })
    .await?;

    // and we’ve seen the update

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if listener.is_empty() {
            bail!("no updates received");
        };
        Ok(())
    })
    .await?;

    // FIXME: name resetting seems to be broken on the synapse side. Getting a server error.

    // // fresh listener
    // let listener = space.subscribe();

    // // reset name to None

    // let _event_id = space.set_name(None).await?;

    // let fetcher_client = user.clone();
    // let space_id_clone = space_id.clone();
    // let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    // Retry::spawn(retry_strategy.clone(), move || {
    //     let client = fetcher_client.clone();
    //     let space_id = space_id_clone.clone();
    //     async move {
    //         if client.space(space_id).await?.name().is_some() {
    //             bail!("Name not set");
    //         }
    //         Ok(())
    //     }
    // })
    // .await?;

    // // and we’ve seen the update

    // Retry::spawn(retry_strategy.clone(), move || {
    //     let mut listener = listener.resubscribe();
    //     async move {
    //         loop {
    //             let res = listener.try_recv();
    //             if matches!(res, Err(TryRecvError::Lagged(_))) {
    //                 // this was an overflow reporting, try again
    //                 continue;
    //             }
    //             return res;
    //         }
    //     }
    // })
    // .await?;

    Ok(())
}

#[tokio::test]
#[ignore = "topic updating seems broken"]
async fn update_topic() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) = random_user_with_template("space_update_topic", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.spaces().await?.len() != 1 {
                bail!("not all spaces found");
            }
            Ok(())
        }
    })
    .await?;

    let mut spaces = user.spaces().await?;

    assert_eq!(spaces.len(), 1);

    let space = spaces.pop().unwrap();
    let listener = space.subscribe();
    let space_id = space.room_id().to_string();

    // set topic

    let _event_id = space.set_topic("New Topic".to_owned()).await?;

    let fetcher_client = user.clone();
    let space_id_clone = space_id.clone();
    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        let space_id = space_id_clone.clone();
        async move {
            let space = client.space(space_id).await?;
            if space.topic() != Some("New topic".to_owned()) {
                bail!("Topic not set");
            }
            Ok(())
        }
    })
    .await?;

    // and we’ve seen the update

    Retry::spawn(retry_strategy.clone(), || async {
        if listener.is_empty() {
            bail!("no updates received");
        }
        Ok(())
    })
    .await?;

    Ok(())
}
