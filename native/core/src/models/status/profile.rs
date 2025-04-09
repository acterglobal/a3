use matrix_sdk_base::ruma::{OwnedMxcUri, OwnedUserId};
use matrix_sdk_ui::timeline::MemberProfileChange;
use serde::{Deserialize, Serialize};

// ruma_events::room::member::change::Change doesn't support serialization
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Change<T> {
    /// The old data.
    pub old_val: T,

    /// The new data.
    pub new_val: T,
}

impl<T: PartialEq> Change<T> {
    pub fn new(old_val: T, new_val: T) -> Option<Self> {
        if old_val == new_val {
            None
        } else {
            Some(Self { old_val, new_val })
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ProfileChange {
    user_id: OwnedUserId,
    display_name_change: Option<Change<Option<String>>>,
    avatar_url_change: Option<Change<Option<OwnedMxcUri>>>,
}

impl From<&MemberProfileChange> for ProfileChange {
    fn from(value: &MemberProfileChange) -> Self {
        ProfileChange {
            user_id: value.user_id().to_owned(),
            display_name_change: value
                .displayname_change()
                .and_then(|c| Change::new(c.new.clone(), c.old.clone())),
            avatar_url_change: value
                .avatar_url_change()
                .and_then(|c| Change::new(c.new.clone(), c.old.clone())),
        }
    }
}

impl ProfileChange {
    pub(crate) fn new(
        user_id: OwnedUserId,
        display_name_change: Option<Change<Option<String>>>,
        avatar_url_change: Option<Change<Option<OwnedMxcUri>>>,
    ) -> Self {
        ProfileChange { user_id, display_name_change, avatar_url_change }
    }

    pub fn user_id(&self) -> OwnedUserId {
        self.user_id.clone()
    }

    pub fn display_name_change(&self) -> Option<String> {
        if let Some(c) = &self.display_name_change {
            match (c.new_val.clone(), c.old_val.clone()) {
                (Some(new_val), Some(old_val)) => {
                    if new_val != old_val {
                        return Some("Changed".to_owned());
                    }
                }
                (None, Some(_old_val)) => {
                    return Some("Unset".to_owned());
                }
                (Some(_new_val), None) => {
                    return Some("Set".to_owned());
                }
                (None, None) => {}
            }
        }
        None
    }

    pub fn display_name_old_val(&self) -> Option<String> {
        self.display_name_change
            .as_ref()
            .and_then(|c| c.old_val.clone())
    }

    pub fn display_name_new_val(&self) -> Option<String> {
        self.display_name_change
            .as_ref()
            .and_then(|c| c.new_val.clone())
    }

    pub fn avatar_url_change(&self) -> Option<String> {
        if let Some(c) = &self.avatar_url_change {
            match (c.new_val.clone(), c.old_val.clone()) {
                (Some(new_val), Some(old_val)) => {
                    if new_val != old_val {
                        return Some("Changed".to_owned());
                    }
                }
                (None, Some(_old_val)) => {
                    return Some("Unset".to_owned());
                }
                (Some(_new_val), None) => {
                    return Some("Set".to_owned());
                }
                (None, None) => {}
            }
        }
        None
    }

    pub fn avatar_url_old_val(&self) -> Option<OwnedMxcUri> {
        self.avatar_url_change
            .as_ref()
            .and_then(|c| c.old_val.clone())
    }

    pub fn avatar_url_new_val(&self) -> Option<OwnedMxcUri> {
        self.avatar_url_change
            .as_ref()
            .and_then(|c| c.new_val.clone())
    }
}
