use anyhow::Result;
use std::io::Write;
use tempfile::Builder;
use tracing::info;
use uuid::Uuid;

use crate::tests::activities::{all_activities_observer, assert_triggered_with_latest_activity};

use super::{get_latest_activity, setup_accounts};

#[allow(dead_code)]
fn new_room_name(prefix: &str) -> String {
    let uuid = Uuid::new_v4().to_string();
    format!("new-room-{prefix}-{uuid}")
}

#[tokio::test]
async fn change_space_name() -> Result<()> {
    let _ = env_logger::try_init();
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("change-space-name").await?;

    // ensure the roomName works on both
    let activity = get_latest_activity(&admin, room_id.to_string(), "roomName").await?;
    assert_eq!(activity.type_str(), "roomName");
    let room_name = activity
        .room_name()
        .expect("space name should be already assigned");
    // for example, it-room-change-space-name-9a2b3db1-d3f9-4f58-a471-81c04bdaa9f4
    assert!(room_name.contains("change-space-name"));

    let activity = get_latest_activity(&observer, room_id.to_string(), "roomName").await?;
    info!("initial room name event: {}", activity.event_id_str());
    assert_eq!(activity.type_str(), "roomName");
    let room_name = activity
        .room_name()
        .expect("space name should be already assigned");
    // for example, it-room-change-space-name-9a2b3db1-d3f9-4f58-a471-81c04bdaa9f4
    assert!(room_name.contains("change-space-name"));
    assert_eq!(activity.target_url(), "/activities");
    // let new_name = new_room_name("update-space-name");
    // let room = admin.room(room_id.to_string()).await?;
    // room.set_name(new_name).await?;

    // let activity = get_latest_activity(&observer, room_id.to_string(), "roomName").await?;
    // info!("updated room name event: {}", activity.event_id_str());
    // assert_eq!(activity.type_str(), "roomName");
    // let room_name = activity.room_name().expect("space name should be already assigned");
    // info!("new room name: {}", &room_name);
    // // for example, new-room-update-space-name-b5e07b4f-61d6-4fd6-b2ae-d16ddecf0965
    // assert!(room_name.find("update-space-name").is_some());

    Ok(())
}

#[tokio::test]
async fn change_space_avatar() -> Result<()> {
    let _ = env_logger::try_init();
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("change-space-avatar").await?;

    let mut act_obs = all_activities_observer(&observer).await?;

    let bytes = include_bytes!("../fixtures/kingfisher.jpg");
    let mut jpg_file = Builder::new().prefix("Fishy").suffix(".jpg").tempfile()?;
    jpg_file.as_file_mut().write_all(bytes)?;

    // admin changes space avatar
    let room = admin.room(room_id.to_string()).await?;
    let uri = room
        .upload_avatar(jpg_file.path().to_string_lossy().to_string())
        .await?;

    // observer detects the change of space avatar
    let activity = get_latest_activity(&observer, room_id.to_string(), "roomAvatar").await?;
    assert_eq!(activity.type_str(), "roomAvatar");
    let room_avatar = activity
        .room_avatar()
        .expect("space topic should be already assigned");
    assert_eq!(room_avatar, uri.as_str());
    assert_eq!(activity.target_url(), "/activities");
    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;
    Ok(())
}

#[tokio::test]
async fn change_space_topic() -> Result<()> {
    let _ = env_logger::try_init();
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("change-space-topic").await?;

    let mut act_obs = all_activities_observer(&observer).await?;

    // admin changes space topic
    let room = admin.room(room_id.to_string()).await?;
    let topic = "Here is playground";
    room.set_topic(topic.to_owned()).await?;

    // observer detects the change of space topic
    let activity = get_latest_activity(&observer, room_id.to_string(), "roomTopic").await?;
    assert_eq!(activity.type_str(), "roomTopic");
    assert_eq!(activity.room_topic().as_deref(), Some(topic));
    assert_eq!(activity.target_url(), "/activities");
    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;
    Ok(())
}
