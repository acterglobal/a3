use acter_matrix::events::DisplayBuilder;
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

    let state_sync = user.start_sync().await?;
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

    let display = {
        let mut builder = DisplayBuilder::default();
        builder.color(0xffff0000);
        builder.icon("emoji".to_owned(), "🚀".to_owned());
        builder.build()?
    };

    let title = "Campaigns";
    let new_cat = {
        let mut builder = space_cats.new_category_builder();
        builder.add_entry("a".to_owned());
        builder.add_entry("b".to_owned());
        builder.add_entry("c".to_owned());
        builder.title(title.to_owned());
        builder.display(Box::new(display));
        builder.build()?
    };

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
    assert_eq!(campaign.title(), title);
    assert_eq!(
        campaign.entries(),
        ["a".to_owned(), "b".to_owned(), "c".to_owned()]
    );
    assert_eq!(campaign.display().and_then(|d| d.color()), Some(0xffff0000));

    let chat_cats = space.categories("chats".to_owned()).await?;
    assert!(chat_cats.categories().is_empty());

    // let’s overwrite it
    let updated = {
        let mut builder = campaign.update_builder();
        builder.title("Backoffice".to_owned());
        builder.clear_entries();
        builder.unset_display();
        builder.build()?
    };

    let display = {
        let mut builder = DisplayBuilder::default();
        builder.color(0xffff0000);
        builder.icon("emoji".to_owned(), "🚀".to_owned());
        builder.unset_color();
        builder.unset_icon();
        builder.build()?
    };

    let new_cat = {
        let mut builder = new_space_categories.new_category_builder();
        builder.add_entry("c".to_owned());
        builder.add_entry("b".to_owned());
        builder.add_entry("a".to_owned());
        builder.title(title.to_owned());
        builder.display(Box::new(display));
        builder.build()?
    };

    let mut space_cat_updater = new_space_categories.update_builder();
    space_cat_updater.clear();
    space_cat_updater.add(Box::new(updated.clone()));
    // and we add a second now.
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
    assert_eq!(categories[0].display(), None);
    assert_eq!(categories[1].display().and_then(|d| d.color()), None);
    assert_eq!(
        categories[1].display().and_then(|d| d.icon_type_str()),
        None
    );
    assert_eq!(categories[1].display().and_then(|d| d.icon_str()), None);

    let chat_cats = space.categories("chats".to_owned()).await?;
    assert!(chat_cats.categories().is_empty());

    Ok(())
}
