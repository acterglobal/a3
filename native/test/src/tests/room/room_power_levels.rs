use acter::api::TimelineItem;
use anyhow::Result;
use core::time::Duration;
use futures::{pin_mut, stream::StreamExt, FutureExt};
use matrix_sdk_base::ruma::events::TimelineEventType;
use tokio::time::sleep;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user_with_random_convo;

#[tokio::test]
async fn test_room_power_levels_ban() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("room_power_levels_ban").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.convo(room_id.to_string()).await }
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream();
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let ban_event_id = convo.set_power_levels_ban(100).await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found_event_id = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" | "Set" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(event_id) = match_ban_msg(&value, "Changed", 100) {
                        found_event_id = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(event_id) = match_ban_msg(value, "Changed", 100) {
                            found_event_id = Some(event_id);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found_event_id.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    assert_eq!(
        found_event_id,
        Some(ban_event_id.to_string()),
        "Even after 30 seconds, ban of room power levels not received",
    );

    Ok(())
}

fn match_ban_msg(msg: &TimelineItem, change: &str, new_val: i64) -> Option<String> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let Some(content) = event_item.room_power_levels_content() else {
        return None;
    };
    if let Some(chg) = content.ban_change() {
        if chg != change {
            return None;
        }
    }
    if content.ban_new_val() != new_val {
        return None;
    }
    event_item.event_id()
}

#[tokio::test]
async fn test_room_power_levels_events() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("room_power_levels_events").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.convo(room_id.to_string()).await }
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream();
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let event_type = TimelineEventType::RoomAvatar.to_string();
    let level_event_id = convo
        .set_power_levels_events(event_type.to_owned(), 100)
        .await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found_event_id = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" | "Set" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(event_id) =
                        match_events_msg(&value, "Changed", event_type.as_str(), 100)
                    {
                        found_event_id = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(event_id) =
                            match_events_msg(value, "Changed", event_type.as_str(), 100)
                        {
                            found_event_id = Some(event_id);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found_event_id.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    assert_eq!(
        found_event_id,
        Some(level_event_id.to_string()),
        "Even after 30 seconds, events of room power levels not received",
    );

    Ok(())
}

fn match_events_msg(msg: &TimelineItem, change: &str, key: &str, level: i64) -> Option<String> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let Some(content) = event_item.room_power_levels_content() else {
        return None;
    };
    if let Some(chg) = content.events_change() {
        if chg != change {
            return None;
        }
    }
    if content.events_new_val(key.to_owned()) != level {
        return None;
    }
    event_item.event_id()
}

#[tokio::test]
async fn test_room_power_levels_events_default() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) =
        random_user_with_random_convo("room_power_levels_events_default").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.convo(room_id.to_string()).await }
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream();
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let default_event_id = convo.set_power_levels_events_default(50).await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found_event_id = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" | "Set" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(event_id) = match_events_default_msg(&value, "Changed", 50) {
                        found_event_id = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(event_id) = match_events_default_msg(value, "Changed", 50) {
                            found_event_id = Some(event_id);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found_event_id.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    assert_eq!(
        found_event_id,
        Some(default_event_id.to_string()),
        "Even after 30 seconds, events_default of room power levels not received",
    );

    Ok(())
}

fn match_events_default_msg(msg: &TimelineItem, change: &str, new_val: i64) -> Option<String> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let Some(content) = event_item.room_power_levels_content() else {
        return None;
    };
    if let Some(chg) = content.events_default_change() {
        if chg != change {
            return None;
        }
    }
    if content.events_default_new_val() != new_val {
        return None;
    }
    event_item.event_id()
}

#[tokio::test]
async fn test_room_power_levels_invite() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("room_power_levels_invite").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.convo(room_id.to_string()).await }
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream();
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let invite_event_id = convo.set_power_levels_invite(50).await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found_event_id = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" | "Set" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(event_id) = match_invite_msg(&value, "Changed", 50) {
                        found_event_id = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(event_id) = match_invite_msg(value, "Changed", 50) {
                            found_event_id = Some(event_id);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found_event_id.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    assert_eq!(
        found_event_id,
        Some(invite_event_id.to_string()),
        "Even after 30 seconds, invite of room power levels not received",
    );

    Ok(())
}

fn match_invite_msg(msg: &TimelineItem, change: &str, new_val: i64) -> Option<String> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let Some(content) = event_item.room_power_levels_content() else {
        return None;
    };
    if let Some(chg) = content.invite_change() {
        if chg != change {
            return None;
        }
    }
    if content.invite_new_val() != new_val {
        return None;
    }
    event_item.event_id()
}

#[tokio::test]
async fn test_room_power_levels_kick() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("room_power_levels_kick").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.convo(room_id.to_string()).await }
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream();
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let kick_event_id = convo.set_power_levels_kick(100).await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found_event_id = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" | "Set" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(event_id) = match_kick_msg(&value, "Changed", 100) {
                        found_event_id = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(event_id) = match_kick_msg(value, "Changed", 100) {
                            found_event_id = Some(event_id);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found_event_id.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    assert_eq!(
        found_event_id,
        Some(kick_event_id.to_string()),
        "Even after 30 seconds, kick of room power levels not received",
    );

    Ok(())
}

fn match_kick_msg(msg: &TimelineItem, change: &str, new_val: i64) -> Option<String> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let Some(content) = event_item.room_power_levels_content() else {
        return None;
    };
    if let Some(chg) = content.kick_change() {
        if chg != change {
            return None;
        }
    }
    if content.kick_new_val() != new_val {
        return None;
    }
    event_item.event_id()
}

#[tokio::test]
async fn test_room_power_levels_redact() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("room_power_levels_redact").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.convo(room_id.to_string()).await }
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream();
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let redact_event_id = convo.set_power_levels_redact(100).await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found_event_id = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" | "Set" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(event_id) = match_redact_msg(&value, "Changed", 100) {
                        found_event_id = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(event_id) = match_redact_msg(value, "Changed", 100) {
                            found_event_id = Some(event_id);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found_event_id.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    assert_eq!(
        found_event_id,
        Some(redact_event_id.to_string()),
        "Even after 30 seconds, redact of room power levels not received",
    );

    Ok(())
}

fn match_redact_msg(msg: &TimelineItem, change: &str, new_val: i64) -> Option<String> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let Some(content) = event_item.room_power_levels_content() else {
        return None;
    };
    if let Some(chg) = content.redact_change() {
        if chg != change {
            return None;
        }
    }
    if content.redact_new_val() != new_val {
        return None;
    }
    event_item.event_id()
}

#[tokio::test]
async fn test_room_power_levels_state_default() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) =
        random_user_with_random_convo("room_power_levels_state_default").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.convo(room_id.to_string()).await }
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream();
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let default_event_id = convo.set_power_levels_state_default(100).await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found_event_id = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" | "Set" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(event_id) = match_state_default_msg(&value, "Changed", 100) {
                        found_event_id = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(event_id) = match_state_default_msg(value, "Changed", 100) {
                            found_event_id = Some(event_id);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found_event_id.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    assert_eq!(
        found_event_id,
        Some(default_event_id.to_string()),
        "Even after 30 seconds, state_default of room power levels not received",
    );

    Ok(())
}

fn match_state_default_msg(msg: &TimelineItem, change: &str, new_val: i64) -> Option<String> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let Some(content) = event_item.room_power_levels_content() else {
        return None;
    };
    if let Some(chg) = content.state_default_change() {
        if chg != change {
            return None;
        }
    }
    if content.state_default_new_val() != new_val {
        return None;
    }
    event_item.event_id()
}

#[tokio::test]
async fn test_room_power_levels_users_default() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) =
        random_user_with_random_convo("room_power_levels_users_default").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.convo(room_id.to_string()).await }
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream();
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let default_event_id = convo.set_power_levels_users_default(50).await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found_event_id = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" | "Set" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(event_id) = match_users_default_msg(&value, "Changed", 50) {
                        found_event_id = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(event_id) = match_users_default_msg(value, "Changed", 50) {
                            found_event_id = Some(event_id);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found_event_id.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    assert_eq!(
        found_event_id,
        Some(default_event_id.to_string()),
        "Even after 30 seconds, users_default of room power levels not received",
    );

    Ok(())
}

fn match_users_default_msg(msg: &TimelineItem, change: &str, new_val: i64) -> Option<String> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let Some(content) = event_item.room_power_levels_content() else {
        return None;
    };
    if let Some(chg) = content.users_default_change() {
        if chg != change {
            return None;
        }
    }
    if content.users_default_new_val() != new_val {
        return None;
    }
    event_item.event_id()
}

#[tokio::test]
async fn test_room_power_levels_notifications() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) =
        random_user_with_random_convo("room_power_levels_notifications").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.convo(room_id.to_string()).await }
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream();
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let notifications_event_id = convo.set_power_levels_notifications(100).await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found_event_id = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" | "Set" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(event_id) = match_notifications_msg(&value, "Changed", 100) {
                        found_event_id = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(event_id) = match_notifications_msg(value, "Changed", 100) {
                            found_event_id = Some(event_id);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found_event_id.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    assert_eq!(
        found_event_id,
        Some(notifications_event_id.to_string()),
        "Even after 30 seconds, notifications of room power levels not received",
    );

    Ok(())
}

fn match_notifications_msg(msg: &TimelineItem, change: &str, new_val: i64) -> Option<String> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let Some(content) = event_item.room_power_levels_content() else {
        return None;
    };
    if let Some(chg) = content.notifications_change() {
        if chg != change {
            return None;
        }
    }
    if content.notifications_new_val() != new_val {
        return None;
    }
    event_item.event_id()
}
