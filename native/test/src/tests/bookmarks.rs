use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user;

#[tokio::test]
async fn bookmarks_e2e() -> Result<()> {
    let _ = env_logger::try_init();
    let mut user = random_user("categories-e2e").await?;

    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    let account = user.account()?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let bookmarks = account.bookmarks().await?;

    assert!(bookmarks.entries("pins".to_owned()).is_empty());
    assert!(bookmarks.entries("news".to_owned()).is_empty());
    assert!(bookmarks.entries("events".to_owned()).is_empty());

    bookmarks.add("pins".to_owned(), "AsdfG".to_owned()).await?;
    let bookmarks = Retry::spawn(retry_strategy.clone(), || async {
        let bookmarks = account.bookmarks().await?;
        if bookmarks.entries("pins".to_owned()).is_empty() {
            bail!("Bookmarks not found");
        }
        Ok(bookmarks)
    })
    .await?;

    assert_eq!(bookmarks.entries("pins".to_owned()), vec!["AsdfG"]);
    assert!(bookmarks.entries("news".to_owned()).is_empty());
    assert!(bookmarks.entries("events".to_owned()).is_empty());

    // adding it again, doesn’t actually add it again
    bookmarks.add("pins".to_owned(), "AsdfG".to_owned()).await?;
    let bookmarks = Retry::spawn(retry_strategy.clone(), || async {
        let bookmarks = account.bookmarks().await?;
        if !bookmarks.entries("pins".to_owned()).is_empty() {
            Ok(bookmarks)
        } else {
            bail!("Bookmarks not found");
        }
    })
    .await?;

    // add another
    assert_eq!(bookmarks.entries("pins".to_owned()), vec!["AsdfG"]);
    assert!(bookmarks.entries("news".to_owned()).is_empty());
    assert!(bookmarks.entries("events".to_owned()).is_empty());

    bookmarks
        .add("pins".to_owned(), "SEcDondD".to_owned())
        .await?;
    let bookmarks = Retry::spawn(retry_strategy.clone(), || async {
        let bookmarks = account.bookmarks().await?;
        if bookmarks.entries("pins".to_owned()).len() == 2 {
            Ok(bookmarks)
        } else {
            bail!("Bookmarks not found");
        }
    })
    .await?;

    assert_eq!(
        bookmarks.entries("pins".to_owned()),
        vec!["AsdfG", "SEcDondD"]
    );
    assert!(bookmarks.entries("news".to_owned()).is_empty());
    assert!(bookmarks.entries("events".to_owned()).is_empty());

    // add different type

    bookmarks.add("news".to_owned(), "super".to_owned()).await?;
    let bookmarks = Retry::spawn(retry_strategy.clone(), || async {
        let bookmarks = account.bookmarks().await?;
        if !bookmarks.entries("news".to_owned()).is_empty() {
            Ok(bookmarks)
        } else {
            bail!("Bookmarks not found");
        }
    })
    .await?;

    assert_eq!(
        bookmarks.entries("pins".to_owned()),
        vec!["AsdfG", "SEcDondD"]
    );
    assert_eq!(bookmarks.entries("news".to_owned()), vec!["super"]);
    assert!(bookmarks.entries("events".to_owned()).is_empty());

    // test remove
    bookmarks
        .remove("pins".to_owned(), "AsdfG".to_owned())
        .await?;
    let bookmarks = Retry::spawn(retry_strategy, || async {
        let bookmarks = account.bookmarks().await?;
        if bookmarks.entries("pins".to_owned()).len() == 1 {
            Ok(bookmarks)
        } else {
            bail!("Bookmarks not found");
        }
    })
    .await?;

    assert_eq!(bookmarks.entries("pins".to_owned()), vec!["SEcDondD"]);
    assert_eq!(bookmarks.entries("news".to_owned()), vec!["super"]);
    assert!(bookmarks.entries("events".to_owned()).is_empty());
    Ok(())
}
