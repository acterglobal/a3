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
    let space = Retry::spawn(retry_strategy.clone(), || async {
        user.space(room_id.to_string()).await
    })
    .await?;

    let space_cats = space.categories("spaces".to_owned()).await?;

    assert!(space_cats.categories().is_empty());

    let chat_cats = space.categories("chats".to_owned()).await?;
    assert!(chat_cats.categories().is_empty());

    let mut new_cat_builder = space_cats.new_category_builder();
    new_cat_builder.add_entry("a".to_owned());
    new_cat_builder.add_entry("b".to_owned());
    new_cat_builder.add_entry("c".to_owned());
    new_cat_builder.title("Campaigns".to_owned());
    let new_cat = new_cat_builder.build()?;

    let mut space_cat_updater = space_cats.update_builder();
    space_cat_updater.add(Box::new(new_cat.clone()));

    space
        .set_categories("spaces".to_owned(), Box::new(space_cat_updater))
        .await?;

    let new_space_categories = Retry::spawn(retry_strategy.clone(), || async {
        let categories = space.categories("spaces".to_owned()).await?;
        if categories.categories().is_empty() {
            bail!("No updated list of categories found")
        }
        Ok(categories)
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
    let mut updater = campaign.update_builder();
    updater.title("Backoffice".to_owned());
    let updated = updater.build()?;

    let mut space_cat_updater = new_space_categories.update_builder();
    space_cat_updater.clear();
    space_cat_updater.add(Box::new(updated.clone()));

    // and we add a second now.
    let mut new_cat_builder = new_space_categories.new_category_builder();
    new_cat_builder.add_entry("c".to_owned());
    new_cat_builder.add_entry("b".to_owned());
    new_cat_builder.add_entry("a".to_owned());
    new_cat_builder.title("Campaigns".to_owned());
    let new_cat = new_cat_builder.build()?;
    space_cat_updater.add(Box::new(new_cat.clone()));

    space
        .set_categories("spaces".to_owned(), Box::new(space_cat_updater))
        .await?;

    let new_new_space_categories = Retry::spawn(retry_strategy, || async {
        let categories = space.categories("spaces".to_owned()).await?;
        if categories.categories().len() != 2 {
            bail!("Not all categories found")
        }
        Ok(categories)
    })
    .await?;

    let categories = new_new_space_categories.categories();
    assert_eq!(categories, [updated, new_cat]);

    let chat_cats = space.categories("chats".to_owned()).await?;
    assert!(chat_cats.categories().is_empty());

    Ok(())
}
