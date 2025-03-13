use acter::{Activity, Client};
use anyhow::{bail, Result};
use futures::{pin_mut, StreamExt};
use std::future;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

mod attachments;
mod calendar;
mod likes;
mod status;

async fn get_latest_activity(
    cl: &Client,
    room_id: String,
    activity_type: &str,
) -> Result<Activity> {
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let observer_room_activities = cl.activities_for_room(room_id)?;

    // check the create event
    let room_activities = observer_room_activities.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let room_activities = room_activities.clone();
        async move {
            let stream = room_activities.iter().await?;
            pin_mut!(stream);
            let Some(a) = stream
                .filter(|f| future::ready(f.type_str() == activity_type))
                .next()
                .await
            else {
                bail!("activity not found")
            };
            cl.activity(a.event_meta().event_id.to_string()).await
        }
    })
    .await
}
