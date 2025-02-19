use matrix_sdk_base::ruma::push::{Action, NewConditionalPushRule, NewPushRule, PushCondition};

pub fn default_rules() -> Vec<NewPushRule> {
    vec![
        // always notify about news as a default
        NewPushRule::Underride(NewConditionalPushRule::new(
            "global.acter.dev.news".to_owned(),
            vec![PushCondition::EventMatch {
                key: "type".to_owned(),
                pattern: "global.acter.dev.news".to_owned(),
            }],
            vec![Action::Notify],
        )),
    ]
}
