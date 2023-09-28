use ruma_common::{events::AnyInitialStateEvent, serde::Raw, OwnedRoomAliasId};
use serde_json::{json, value::to_raw_value};

pub static PURPOSE_FIELD: &str = "m.room.purpose";
pub static PURPOSE_FIELD_DEV: &str = "org.matrix.msc3088.room.purpose";
pub static PURPOSE_TEAM_VALUE: &str = "global.acter.team";

#[allow(non_snake_case)]
pub mod KEYS {
    pub static TASKS: &str = "tasks";
    pub static CALENDAR: &str = "calendar";
    pub static NEWS: &str = "news";
    pub static PINS: &str = "pins";
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

/// Generate the default set ot initial states for acter teams
pub fn default_acter_space_states() -> Vec<Raw<AnyInitialStateEvent>> {
    let mut v = [HISTORY]
        .into_iter()
        .map(|a| serde_json::from_str::<Raw<AnyInitialStateEvent>>(a).expect("static don't fail"))
        .collect::<Vec<Raw<AnyInitialStateEvent>>>();
    let r = to_raw_value(&json!({
        "type": PURPOSE_FIELD_DEV,
        "state_key": PURPOSE_TEAM_VALUE,
        "content": {
            "m.enabled": true,
            "m.importance_level": 50
        }
    }))
    .expect("static parsing of subtype doesn't fail");

    v.push(Raw::from_json(r));
    v
}

pub fn default_acter_convo_states() -> Vec<Raw<AnyInitialStateEvent>> {
    [HISTORY, ENCRYPTION]
        .into_iter()
        .map(|a| serde_json::from_str::<Raw<AnyInitialStateEvent>>(a).expect("static don't fail"))
        .collect()
}

pub fn initial_state_for_alias(
    main_alias: &OwnedRoomAliasId,
    alt_aliases: &Vec<OwnedRoomAliasId>,
) -> Raw<AnyInitialStateEvent> {
    let r = to_raw_value(&json!({
        "type": "m.room.canonical_alias",
        "state_key": "",
        "content": {
            "alias": Some(main_alias),
            "alt_aliases": alt_aliases,
        }
    }))
    .expect("static doesn't fail");

    Raw::from_json(r)
}
