use acter::new_space_settings_builder;
use anyhow::{bail, Result};
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
name = "{{ main.display_name }}'s main test space"

[objects.second_space]
type = "space"
name = "{{ main.display_name }}'s first test space"

[objects.third_space]
type = "space"
name = "{{ main.display_name }}'s second test space"
"#;

#[tokio::test]
async fn spaces_deleted() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, _sync_state, _engine) =
        random_user_with_template("spaces-deleted-", THREE_SPACES_TMPL).await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.spaces().await?.len() != 3 {
                bail!("not all spaces found");
            } else {
                Ok(())
            }
        }
    })
    .await?;

    let mut spaces = user.spaces().await?;

    assert_eq!(spaces.len(), 3);

    let first = spaces.pop().unwrap();
    let second = spaces.pop().unwrap();
    let last = spaces.pop().unwrap();

    let all_listener = user.subscribe("SPACES".to_owned());
    let mut first_listener = user.subscribe(first.room_id().to_string());
    let mut second_listener = user.subscribe(second.room_id().to_string());
    let mut last_listener = user.subscribe(last.room_id().to_string());

    first.leave().await?;
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.spaces().await?.len() != 2 {
                bail!("not the right number of spaces found");
            } else {
                Ok(())
            }
        }
    })
    .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if all_listener.is_empty() {
            bail!("all still empty");
        };
        Ok(())
    })
    .await?;

    println!("all triggered");
    Retry::spawn(retry_strategy.clone(), || async {
        if first_listener.is_empty() {
            // not yet.
            bail!("First still empty");
        }
        Ok(())
    });

    assert!(first_listener.try_recv().is_ok());
    assert_eq!(second_listener.try_recv(), Err(TryRecvError::Empty));
    assert_eq!(last_listener.try_recv(), Err(TryRecvError::Empty));

    // get a second listener
    let all_listener = user.subscribe("SPACES".to_owned());

    second.leave().await?;
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.spaces().await?.len() != 1 {
                bail!("not the right number of spaces found");
            } else {
                Ok(())
            }
        }
    })
    .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if all_listener.is_empty() {
            // this was empty, try again
            bail!("all listeners still empty");
        }
        Ok(())
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
name = "{{ main.display_name }}'s main test space"
"#;

#[tokio::test]
async fn create_subspace() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, _sync_state, _engine) = random_user_with_template("subspaces-create-", TMPL).await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.spaces().await?.len() != 1 {
                bail!("not all spaces found");
            } else {
                Ok(())
            }
        }
    })
    .await?;

    let mut spaces = user.spaces().await?;

    assert_eq!(spaces.len(), 1);

    let first = spaces.pop().unwrap();

    let all_listener = user.subscribe("SPACES".to_owned());
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
            } else {
                Ok(())
            }
        }
    })
    .await?;

    let space = user.space(subspace_id.to_string()).await?;
    let space_relations = space.space_relations().await?;
    let space_parent = space_relations
        .main_parent()
        .expect("Subspace doesn't have the parent");
    assert_eq!(space_parent.room_id(), first.room_id());

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);

    Retry::spawn(retry_strategy.clone(), || async {
        if all_listener.is_empty() {
            bail!("all still empty");
        };
        Ok(())
    })
    .await?;

    Ok(())
}

#[tokio::test]
async fn update_name() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, _sync_state, _engine) =
        random_user_with_template("space-update-name-", TMPL).await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.spaces().await?.len() != 1 {
                bail!("not all spaces found");
            } else {
                Ok(())
            }
        }
    })
    .await?;

    let mut spaces = user.spaces().await?;

    assert_eq!(spaces.len(), 1);

    let space = spaces.pop().unwrap();
    let listener = space.subscribe();
    let space_id = space.room_id().to_string();

    // set name

    let _event_id = space.set_name(Some("New Name".to_owned())).await?;

    let fetcher_client = user.clone();
    let space_id_clone = space_id.clone();
    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        let space_id = space_id_clone.clone();
        async move {
            if client.space(space_id).await?.name() == Some("New Name".to_owned()) {
                Ok(())
            } else {
                bail!("Name not set")
            }
        }
    })
    .await?;

    // and we've seen the update

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if listener.is_empty() {
            bail!("all still empty");
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
    //         if client.space(space_id).await?.name().is_none() {
    //             Ok(())
    //         } else {
    //             bail!("Name not set")
    //         }
    //     }
    // })
    // .await?;

    // // and we've seen the update

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
    let (user, _sync_state, _engine) =
        random_user_with_template("space-update-topic-", TMPL).await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.spaces().await?.len() != 1 {
                bail!("not all spaces found");
            } else {
                Ok(())
            }
        }
    })
    .await?;

    let mut spaces = user.spaces().await?;

    assert_eq!(spaces.len(), 1);

    let space = spaces.pop().unwrap();
    let listener = space.subscribe();
    let space_id = space.room_id().to_string();

    // set topic

    let _event_id = space.set_topic("New topic".to_owned()).await?;

    let fetcher_client = user.clone();
    let space_id_clone = space_id.clone();
    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        let space_id = space_id_clone.clone();
        async move {
            if client.space(space_id).await?.topic() == Some("New topic".to_owned()) {
                Ok(())
            } else {
                bail!("Topic not set")
            }
        }
    })
    .await?;

    // and we've seen the update

    Retry::spawn(retry_strategy.clone(), || async {
        if listener.is_empty() {
            bail!("all still empty");
        };
        Ok(())
    })
    .await?;

    Ok(())
}
