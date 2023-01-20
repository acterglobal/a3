use matrix_sdk::ruma::{events::AnyInitialStateEvent, serde::Raw, OwnedRoomAliasId};
use serde_json::{json, value::to_raw_value};

pub static PURPOSE_FIELD: &str = "m.room.purpose";
pub static PURPOSE_FIELD_DEV: &str = "org.matrix.msc3088.room.purpose";
pub static PURPOSE_TEAM_VALUE: &str = "org.effektio.team";

#[allow(non_snake_case)]
pub mod KEYS {
    pub static TASKS: &str = "tasks";
}

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
    let mut v: Vec<Raw<AnyInitialStateEvent>> = [HISTORY]
        .into_iter()
        .map(|a| serde_json::from_str::<Raw<AnyInitialStateEvent>>(a).expect("static don't fail"))
        .collect();

    v.push(Raw::from_json(
        to_raw_value(&json!({
            "type": PURPOSE_FIELD_DEV,
            "state_key": PURPOSE_TEAM_VALUE,
            "content": {
                "m.enabled": true,
                "m.importance_level": 50
            }
        }))
        .expect("static parsing of subtype doesn't fail"),
    ));
    v
}

pub fn default_effektio_conversation_states() -> Vec<Raw<AnyInitialStateEvent>> {
    [HISTORY, ENCRYPTION]
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
