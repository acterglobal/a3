use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user_with_random_space;

#[tokio::test]
async fn categories_e2e() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("categories-e2e").await?;

    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    let space = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.space(room_id.to_string()).await }
    })
    .await?;

    let space_cats = space.categories("spaces".to_owned()).await?;

    assert!(space_cats.categories().is_empty());

    let chat_cats = space.categories("chats".to_owned()).await?;
    assert!(chat_cats.categories().is_empty());

    let new_cat = space_cats
        .new_category_builder()
        .add_entry("a".to_owned())
        .add_entry("b".to_owned())
        .add_entry("c".to_owned())
        .title("Campaigns".to_owned())
        .build()?;
    let space_cat_updater = space_cats.update_builder().add(Box::new(new_cat.clone()));

    space
        .set_categories("spaces".to_owned(), Box::new(space_cat_updater.clone()))
        .await?;

    let fetching_space = space.clone();
    let new_space_categories = Retry::spawn(retry_strategy.clone(), move || {
        let space = fetching_space.clone();
        async move {
            let categories = space.categories("spaces".to_owned()).await?;
            if categories.categories().is_empty() {
                bail!("No updated list of categories found")
            }
            Ok(categories)
        }
    })
    .await?;

    let categories = new_space_categories.categories();
    assert_eq!(categories.len(), 1, "Exepected one item");
    let campaign = categories[0].clone();
    assert_eq!(campaign, new_cat);
    assert_eq!(
        campaign.entries(),
        ["a".to_owned(), "b".to_owned(), "c".to_owned()]
    );

    let chat_cats = space.categories("chats".to_owned()).await?;
    assert!(chat_cats.categories().is_empty());

    // let’s overwrite it
    let updated = campaign
        .update_builder()
        .title("Backoffice".to_owned())
        .build()?;

    let new_cat = new_space_categories
        .new_category_builder()
        .add_entry("c".to_owned())
        .add_entry("b".to_owned())
        .add_entry("a".to_owned())
        .title("Campaigns".to_owned())
        .build()?;
    let space_cat_updater = new_space_categories
        .update_builder()
        .clear()
        .add(Box::new(updated.clone()))
        // and we add a second now.
        .add(Box::new(new_cat.clone()));

    space
        .set_categories("spaces".to_owned(), Box::new(space_cat_updater.clone()))
        .await?;

    let fetching_space = space.clone();
    let new_new_space_categories = Retry::spawn(retry_strategy, move || {
        let space = fetching_space.clone();
        async move {
            let categories = space.categories("spaces".to_owned()).await?;
            if categories.categories().len() != 2 {
                bail!("Not all categories found")
            }
            Ok(categories)
        }
    })
    .await?;

    let categories = new_new_space_categories.categories();
    assert_eq!(categories, [updated, new_cat]);

    let chat_cats = space.categories("chats".to_owned()).await?;
    assert!(chat_cats.categories().is_empty());

    Ok(())
}
