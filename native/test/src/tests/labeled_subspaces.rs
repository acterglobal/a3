use acter::{api::LabelsBuilder, new_space_settings_builder};
use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::{random_user_with_random_space, random_user_with_template};

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
#[ignore]
async fn create_subspace_with_category() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, _sync_state, _engine) =
        random_user_with_template("subspace_with_category", TMPL).await?;

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
    let space_relations = space.space_relations().await?;
    let space_parent = space_relations
        .main_parent()
        .expect("Subspace doesn't have the parent");
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
async fn labels_end_to_end() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, space_id) = random_user_with_random_space("labels").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;
    let space = user.space(space_id.to_string()).await?;
    let labels = space.labels("spaces.cats".to_owned()).await;
    assert!(labels.is_empty());

    let labels = space.labels("chat.cats".to_owned()).await;
    assert!(labels.is_empty());

    let mut new_labels = LabelsBuilder::default();
    new_labels.add_label("campaigns".to_owned(), "Campaigns".to_owned(), None);
    new_labels.add_label("teams".to_owned(), "Teams".to_owned(), None);
    new_labels.add_label(
        "working-groups".to_owned(),
        "Working Groups".to_owned(),
        None,
    );

    space
        .set_labels("spaces.cats".to_owned(), Box::new(new_labels))
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    let labels = Retry::spawn(retry_strategy.clone(), || async {
        let labels = space.labels("spaces.cats".to_owned()).await;
        if labels.len() != 3 {
            bail!("Labels not yet found");
        }
        Ok(labels)
    })
    .await?;

    let mut labels_iter = labels.into_iter();

    let campaigns = labels_iter.next().unwrap();
    assert_eq!(campaigns.id(), "campaigns".to_owned());
    assert_eq!(campaigns.title(), "Campaigns".to_owned());
    assert!(campaigns.icon().is_none());

    let teams = labels_iter.next().unwrap();
    assert_eq!(teams.id(), "teams".to_owned());
    assert_eq!(teams.title(), "Teams".to_owned());
    assert!(teams.icon().is_none());

    let working_groups = labels_iter.next().unwrap();
    assert_eq!(working_groups.id(), "working-groups".to_owned());
    assert_eq!(working_groups.title(), "Working Groups".to_owned());
    assert!(working_groups.icon().is_none());

    let labels = space.labels("chat.cats".to_owned()).await;
    assert!(labels.is_empty());

    Ok(())
}
