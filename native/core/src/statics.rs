use ruma::serde::Raw;
use ruma::events::{AnyInitialStateEvent, AnyStateEvent};

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
    .map(|a|{
      serde_json::from_str::<Raw<AnyInitialStateEvent>>(a)
        .expect("static don't fail")
    })
    .collect()
}