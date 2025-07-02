use acter::api::TimelineItem;
use acter_matrix::models::status::RoomPowerLevelsContent;
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
    let state_sync = user.start_sync().await?;
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        user.convo(room_id.to_string()).await
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream().await?;
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let new_level: i64 = 100;
    let default_level = 50;
    let ban_event_id = convo.set_power_levels_ban(new_level as i32).await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(content) = match_msg(&value, ban_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Set" => {
                    let value = diff
                        .value()
                        .expect("diff set action should have valid value");
                    if let Some(content) = match_msg(&value, ban_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(content) = match_msg(value, ban_event_id.as_str()) {
                            found = Some(content);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    let content = found.expect("Even after 30 seconds, room power levels not received");

    assert_eq!(
        content.ban_change().as_deref(),
        Some("Changed"),
        "room power levels should be changed"
    );
    assert_eq!(
        content.ban_new_val(),
        new_level,
        "new val of room power levels is invalid"
    );
    assert_eq!(
        content.ban_old_val(),
        Some(default_level),
        "old val of room power levels is invalid"
    );

    Ok(())
}

#[tokio::test]
async fn test_room_power_levels_events() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("room_power_levels_events").await?;
    let state_sync = user.start_sync().await?;
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        user.convo(room_id.to_string()).await
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream().await?;
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let event_type = TimelineEventType::RoomAvatar;
    let new_level: i64 = 100;
    let default_level = 50;
    let level_event_id = convo
        .set_power_levels_events(event_type.to_string(), new_level as i32)
        .await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(content) = match_msg(&value, level_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Set" => {
                    let value = diff
                        .value()
                        .expect("diff set action should have valid value");
                    if let Some(content) = match_msg(&value, level_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(content) = match_msg(value, level_event_id.as_str()) {
                            found = Some(content);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    let content = found.expect("Even after 30 seconds, room power levels not received");

    assert_eq!(
        content.events_change(event_type.to_string()).as_deref(),
        Some("Changed"),
        "room power levels should be changed"
    );
    assert_eq!(
        content.events_new_val(event_type.to_string()),
        Some(new_level),
        "new val of room power levels is invalid"
    );
    assert_eq!(
        content.events_old_val(event_type.to_string()),
        Some(default_level),
        "old val of room power levels is invalid"
    );

    Ok(())
}

#[tokio::test]
async fn test_room_power_levels_events_default() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) =
        random_user_with_random_convo("room_power_levels_events_default").await?;
    let state_sync = user.start_sync().await?;
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        user.convo(room_id.to_string()).await
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream().await?;
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let new_level: i64 = 50;
    let default_level = 0;
    let default_event_id = convo
        .set_power_levels_events_default(new_level as i32)
        .await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(content) = match_msg(&value, default_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Set" => {
                    let value = diff
                        .value()
                        .expect("diff set action should have valid value");
                    if let Some(content) = match_msg(&value, default_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(content) = match_msg(value, default_event_id.as_str()) {
                            found = Some(content);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    let content = found.expect("Even after 30 seconds, room power levels not received");

    assert_eq!(
        content.events_default_change().as_deref(),
        Some("Changed"),
        "room power levels should be changed"
    );
    assert_eq!(
        content.events_default_new_val(),
        new_level,
        "new val of room power levels is invalid"
    );
    assert_eq!(
        content.events_default_old_val(),
        Some(default_level),
        "old val of room power levels is invalid"
    );

    Ok(())
}

#[tokio::test]
async fn test_room_power_levels_invite() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("room_power_levels_invite").await?;
    let state_sync = user.start_sync().await?;
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        user.convo(room_id.to_string()).await
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream().await?;
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let new_level: i64 = 50;
    let default_level = 0;
    let invite_event_id = convo.set_power_levels_invite(new_level as i32).await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(content) = match_msg(&value, invite_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Set" => {
                    let value = diff
                        .value()
                        .expect("diff set action should have valid value");
                    if let Some(content) = match_msg(&value, invite_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(content) = match_msg(value, invite_event_id.as_str()) {
                            found = Some(content);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    let content = found.expect("Even after 30 seconds, room power levels not received");

    assert_eq!(
        content.invite_change().as_deref(),
        Some("Changed"),
        "room power levels should be changed"
    );
    assert_eq!(
        content.invite_new_val(),
        new_level,
        "new val of room power levels is invalid"
    );
    assert_eq!(
        content.invite_old_val(),
        Some(default_level),
        "old val of room power levels is invalid"
    );

    Ok(())
}

#[tokio::test]
async fn test_room_power_levels_kick() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("room_power_levels_kick").await?;
    let state_sync = user.start_sync().await?;
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        user.convo(room_id.to_string()).await
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream().await?;
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let new_level: i64 = 100;
    let default_level = 50;
    let kick_event_id = convo.set_power_levels_kick(new_level as i32).await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(content) = match_msg(&value, kick_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Set" => {
                    let value = diff
                        .value()
                        .expect("diff set action should have valid value");
                    if let Some(content) = match_msg(&value, kick_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(content) = match_msg(value, kick_event_id.as_str()) {
                            found = Some(content);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    let content = found.expect("Even after 30 seconds, room power levels not received");

    assert_eq!(
        content.kick_change().as_deref(),
        Some("Changed"),
        "room power levels should be changed"
    );
    assert_eq!(
        content.kick_new_val(),
        new_level,
        "new val of room power levels is invalid"
    );
    assert_eq!(
        content.kick_old_val(),
        Some(default_level),
        "old val of room power levels is invalid"
    );

    Ok(())
}

#[tokio::test]
async fn test_room_power_levels_redact() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("room_power_levels_redact").await?;
    let state_sync = user.start_sync().await?;
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        user.convo(room_id.to_string()).await
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream().await?;
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let new_level: i64 = 100;
    let default_level = 50;
    let redact_event_id = convo.set_power_levels_redact(new_level as i32).await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(content) = match_msg(&value, redact_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Set" => {
                    let value = diff
                        .value()
                        .expect("diff set action should have valid value");
                    if let Some(content) = match_msg(&value, redact_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(content) = match_msg(value, redact_event_id.as_str()) {
                            found = Some(content);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    let content = found.expect("Even after 30 seconds, room power levels not received");

    assert_eq!(
        content.redact_change().as_deref(),
        Some("Changed"),
        "room power levels should be changed"
    );
    assert_eq!(
        content.redact_new_val(),
        new_level,
        "new val of room power levels is invalid"
    );
    assert_eq!(
        content.redact_old_val(),
        Some(default_level),
        "old val of room power levels is invalid"
    );

    Ok(())
}

#[tokio::test]
async fn test_room_power_levels_state_default() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) =
        random_user_with_random_convo("room_power_levels_state_default").await?;
    let state_sync = user.start_sync().await?;
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        user.convo(room_id.to_string()).await
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream().await?;
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let new_level: i64 = 100;
    let default_level = 50;
    let default_event_id = convo
        .set_power_levels_state_default(new_level as i32)
        .await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(content) = match_msg(&value, default_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Set" => {
                    let value = diff
                        .value()
                        .expect("diff set action should have valid value");
                    if let Some(content) = match_msg(&value, default_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(content) = match_msg(value, default_event_id.as_str()) {
                            found = Some(content);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    let content = found.expect("Even after 30 seconds, room power levels not received");

    assert_eq!(
        content.state_default_change().as_deref(),
        Some("Changed"),
        "room power levels should be changed"
    );
    assert_eq!(
        content.state_default_new_val(),
        new_level,
        "new val of room power levels is invalid"
    );
    assert_eq!(
        content.state_default_old_val(),
        Some(default_level),
        "old val of room power levels is invalid"
    );

    Ok(())
}

#[tokio::test]
async fn test_room_power_levels_users_default() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) =
        random_user_with_random_convo("room_power_levels_users_default").await?;
    let state_sync = user.start_sync().await?;
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        user.convo(room_id.to_string()).await
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream().await?;
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let new_level: i64 = 50;
    let default_level = 0;
    let default_event_id = convo
        .set_power_levels_users_default(new_level as i32)
        .await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(content) = match_msg(&value, default_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Set" => {
                    let value = diff
                        .value()
                        .expect("diff set action should have valid value");
                    if let Some(content) = match_msg(&value, default_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(content) = match_msg(value, default_event_id.as_str()) {
                            found = Some(content);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    let content = found.expect("Even after 30 seconds, room power levels not received");

    assert_eq!(
        content.users_default_change().as_deref(),
        Some("Changed"),
        "room power levels should be changed"
    );
    assert_eq!(
        content.users_default_new_val(),
        new_level,
        "new val of room power levels is invalid"
    );
    assert_eq!(
        content.users_default_old_val(),
        Some(default_level),
        "old val of room power levels is invalid"
    );

    Ok(())
}

#[tokio::test]
async fn test_room_power_levels_notifications() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) =
        random_user_with_random_convo("room_power_levels_notifications").await?;
    let state_sync = user.start_sync().await?;
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        user.convo(room_id.to_string()).await
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream().await?;
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let new_level: i64 = 100;
    let default_level = 50;
    let notifications_event_id = convo
        .set_power_levels_notifications(new_level as i32)
        .await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(content) = match_msg(&value, notifications_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Set" => {
                    let value = diff
                        .value()
                        .expect("diff set action should have valid value");
                    if let Some(content) = match_msg(&value, notifications_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(content) = match_msg(value, notifications_event_id.as_str()) {
                            found = Some(content);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    let content = found.expect("Even after 30 seconds, room power levels not received");

    assert_eq!(
        content.notifications_change().as_deref(),
        Some("Changed"),
        "room power levels should be changed"
    );
    assert_eq!(
        content.notifications_new_val(),
        new_level,
        "new val of room power levels is invalid"
    );
    assert_eq!(
        content.notifications_old_val(),
        Some(default_level),
        "old val of room power levels is invalid"
    );

    Ok(())
}

fn match_msg(msg: &TimelineItem, event_id: &str) -> Option<RoomPowerLevelsContent> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    if event_item.event_id().as_deref() != Some(event_id) {
        return None;
    }
    event_item.room_power_levels_content()
}
