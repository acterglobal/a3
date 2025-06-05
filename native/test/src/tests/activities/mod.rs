use acter::{Activities, Activity, Client, SyncState};
use anyhow::{bail, Result};
use futures::{pin_mut, StreamExt};
use matrix_sdk::ruma::OwnedRoomId;
use std::future;
use tokio::sync::broadcast::Receiver;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_users_with_random_space;

mod attachments;
mod calendar;
mod comments;
mod likes;
mod policy_rule_room;
mod policy_rule_server;
mod policy_rule_user;
mod room_avatar;
mod room_create;
mod room_encryption;
mod room_guest_access;
mod room_history_visibility;
mod room_join_rules;
mod room_name;
mod room_pinned_events;
mod room_power_levels;
mod room_server_acl;
mod room_tombstone;
mod room_topic;
mod space;
mod space_child;
mod space_parent;
mod status;
mod tasks;

async fn get_latest_activity(
    cl: &Client,
    room_id: String,
    activity_type: &str,
) -> Result<Activity> {
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let observer_room_activities = cl.activities_for_room(room_id)?;

    // check the create event
    Retry::spawn(retry_strategy, || async {
        let stream = observer_room_activities.iter().await?;
        pin_mut!(stream);
        let Some(a) = stream
            .filter(|f| future::ready(f.type_str() == activity_type))
            .next()
            .await
        else {
            bail!("activity not found")
        };
        cl.activity(a.event_meta().event_id.to_string()).await
    })
    .await
}

async fn setup_accounts(
    prefix: &str,
) -> Result<((Client, SyncState), (Client, SyncState), OwnedRoomId)> {
    let (users, room_id) = random_users_with_random_space(prefix, 2).await?;
    let mut admin = users[0].clone();
    let mut observer = users[1].clone();

    observer.install_default_acter_push_rules().await?;

    let sync_state1 = admin.start_sync();
    sync_state1.await_has_synced_history().await?;

    let sync_state2 = observer.start_sync();
    sync_state2.await_has_synced_history().await?;

    Ok(((admin, sync_state1), (observer, sync_state2), room_id))
}

pub(crate) type ActivitiesAndRcv = (Activities, Receiver<()>);

pub(crate) async fn all_activities_observer(cl: &Client) -> Result<ActivitiesAndRcv> {
    let activities = cl.all_activities()?;
    let rcv = activities.subscribe();
    Ok((activities, rcv))
}

pub(crate) async fn assert_triggered_with_latest_activity(
    activities_and_rcv: &mut ActivitiesAndRcv,
    latest_activity_id: String,
) -> Result<()> {
    let (activities, rcv) = activities_and_rcv;
    let mut counter = 10;
    while counter > 0 {
        if rcv.try_recv().is_ok() {
            break;
        }
        counter -= 1;
        tokio::time::sleep(std::time::Duration::from_millis(300)).await;
    }
    if counter == 0 {
        bail!("Activity stream did not trigger, event after 3 seconds");
    }
    assert_latest_activity(activities, latest_activity_id).await?;
    Ok(())
}

pub(crate) async fn assert_latest_activity(
    activities: &Activities,
    latest_activity_id: String,
) -> Result<()> {
    assert_eq!(
        activities.get_ids(0, 1).await?,
        vec![latest_activity_id],
        "Latest activity id is not the expected one"
    );
    Ok(())
}
