use acter_core::activities::ActivityContent;
use anyhow::{bail, Result};
use matrix_sdk_base::ruma::events::policy::rule::Recommendation;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use super::setup_accounts;

#[tokio::test]
async fn test_policy_rule_user() -> Result<()> {
    let _ = env_logger::try_init();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let ((admin, _handle1), (observer, _handle2), room_id) =
        setup_accounts("policy-rule-user").await?;

    let room = admin.room(room_id.to_string()).await?;
    let room_activities = observer.activities_for_room(room_id.to_string())?;
    let mut activities_listenerd = room_activities.subscribe();

    // ensure it was sent
    let policy_event_id = room
        .set_policy_rule_user(
            "@alice*:example.org".to_owned(),
            "undesirable behaviour".to_owned(),
        )
        .await?;

    activities_listenerd.recv().await?; // await for it have been coming in

    // wait for the event to come in
    let cl = observer.clone();
    let activity = Retry::spawn(retry_strategy, move || {
        let room_activities = room_activities.clone();
        let cl = cl.clone();
        async move {
            let m = room_activities.get_ids(0, 1).await?;
            let Some(id) = m.first().cloned() else {
                bail!("no latest room activity found");
            };
            cl.activity(id).await
        }
    })
    .await?;

    // external API check
    let meta = activity.event_meta();
    assert_eq!(
        meta.event_id.clone(),
        policy_event_id,
        "event id should match"
    );
    assert_eq!(activity.sender_id_str(), admin.user_id()?);
    assert_eq!(activity.event_id_str(), meta.event_id.to_string());
    assert_eq!(activity.room_id_str(), room.room_id_str());
    assert_eq!(activity.type_str(), "policyRuleUser");
    assert_eq!(
        activity.origin_server_ts(),
        Into::<u64>::into(meta.origin_server_ts.get())
    );

    // check the content of activity
    let content = activity
        .policy_rule_user_content()
        .expect("not a policy rule user event");

    assert_eq!(
        content.entity_change(),
        Some("Set".to_owned()),
        "entity in policy rule user should be set"
    );
    assert_eq!(
        content.entity_new_val(),
        "@alice*:example.org",
        "new val of entity in policy rule user is invalid"
    );
    assert_eq!(
        content.entity_old_val(),
        None,
        "old val of entity in policy rule user is invalid"
    );

    assert_eq!(
        content.recommendation_change(),
        Some("Set".to_owned()),
        "recommendation in policy rule user should be set"
    );
    assert_eq!(
        content.recommendation_new_val(),
        Recommendation::Ban.as_str(),
        "new val of recommendation in policy rule user is invalid"
    );
    assert_eq!(
        content.recommendation_old_val(),
        None,
        "old val of recommendation in policy rule user is invalid"
    );

    assert_eq!(
        content.reason_change(),
        Some("Set".to_owned()),
        "reason in policy rule user should be set"
    );
    assert_eq!(
        content.reason_new_val(),
        "undesirable behaviour",
        "new val of reason in policy rule user is invalid"
    );
    assert_eq!(
        content.reason_old_val(),
        None,
        "old val of reason in policy rule user is invalid"
    );

    Ok(())
}
