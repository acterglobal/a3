use matrix_sdk::ruma::{events::AnyInitialStateEvent, serde::Raw, OwnedRoomAliasId};
use serde_json::{json, value::to_raw_value};

const EFFEKTIO_SUBTYPE_CONTENT: &str = r#"{
  "type": "m.room.purpose",
  "state_key": "effektio.team",
  "content": {
    "m.enabled": true,
    "m.importance_level": 50
  }
}"#;

const HISTORY: &str = r#"{
  "type": "m.room.history_visibility",
  "state_key": "",
  "content": {
    "history_visibility": "shared"
  }
}"#;

const ENCRYPTION: &str = r#"{
  "type": "m.room.encryption",
  "state_key": "",
  "content": {
      "algorithm": "m.megolm.v1.aes-sha2",
      "rotation_period_ms": 604800000,
      "rotation_period_msgs": 100
  }
}"#;

/// Generate the default set ot initial states for effektio teams
pub fn default_effektio_group_states() -> Vec<Raw<AnyInitialStateEvent>> {
    [EFFEKTIO_SUBTYPE_CONTENT, HISTORY, ENCRYPTION]
        .into_iter()
        .map(|a| serde_json::from_str::<Raw<AnyInitialStateEvent>>(a).expect("static don't fail"))
        .collect()
}

pub fn initial_state_for_alias(
    main_alias: &OwnedRoomAliasId,
    alt_aliases: &Vec<OwnedRoomAliasId>,
) -> Raw<AnyInitialStateEvent> {
    Raw::from_json(
        to_raw_value(&json!({
        "type": "m.room.canonical_alias",
        "state_key": "",
        "content": {
            "alias": Some(main_alias),
            "alt_aliases": alt_aliases,
          }
        }))
        .expect("static doesn't fail"),
    )
}
