use std::ops::Deref;

pub use acter_core::activities::object::ActivityObject;
use acter_core::{
    activities::Activity as CoreActivity,
    events::news::{FallbackNewsContent, NewsContent},
    models::{
        status::{
            MembershipContent, PolicyRuleRoomContent, PolicyRuleServerContent,
            PolicyRuleUserContent, ProfileContent, RoomAvatarContent, RoomCreateContent,
            RoomEncryptionContent, RoomGuestAccessContent, RoomHistoryVisibilityContent,
            RoomJoinRulesContent, RoomNameContent, RoomPinnedEventsContent, RoomPowerLevelsContent,
            RoomServerAclContent, RoomTombstoneContent, RoomTopicContent, SpaceChildContent,
            SpaceParentContent,
        },
        ActerModel,
    },
    referencing::IndexKey,
};
use futures::{FutureExt, Stream, StreamExt};
use matrix_sdk::ruma::{EventId, OwnedEventId, OwnedRoomId, RoomId};
use tokio::sync::broadcast::Receiver;
use tokio_stream::wrappers::BroadcastStream;
use tracing::error;

use super::{Client, MsgContent, RefDetails, RUNTIME};

use acter_core::activities::ActivityContent;

#[derive(Clone, Debug)]
pub struct Activity {
    inner: CoreActivity,
    client: Client,
}

impl Activity {
    pub fn content(&self) -> &ActivityContent {
        self.inner.content()
    }

    pub fn sender_id_str(&self) -> String {
        self.inner.event_meta().sender.to_string()
    }

    pub fn origin_server_ts(&self) -> u64 {
        self.inner.event_meta().origin_server_ts.get().into()
    }

    pub fn room_id_str(&self) -> String {
        self.inner.event_meta().room_id.to_string()
    }

    pub fn event_id_str(&self) -> String {
        self.inner.event_meta().event_id.to_string()
    }

    pub fn ref_details(&self) -> Option<RefDetails> {
        self.inner
            .ref_details()
            .map(|r| RefDetails::new(self.client.core.client().clone(), r))
    }

    pub fn msg_content(&self) -> Option<MsgContent> {
        match self.inner.content() {
            ActivityContent::DescriptionChange { content, .. } => match content.change().as_str() {
                "Changed" | "Set" => {
                    if let Some(new_val) = content.new_val.as_ref() {
                        Some(MsgContent::from(new_val.clone()))
                    } else {
                        error!("Could not get the new value for the description change");
                        None
                    }
                }
                "Unset" => Some(MsgContent::from_text("removed description".to_owned())),
                _ => None,
            },
            ActivityContent::Comment { content, .. } => Some(MsgContent::from(content)),
            ActivityContent::Boost {
                first_slide: Some(first_slide),
                ..
            } => MsgContent::try_from(first_slide).ok(),
            _ => None,
        }
    }

    pub fn membership_content(&self) -> Option<MembershipContent> {
        self.inner.membership_content()
    }

    pub fn profile_content(&self) -> Option<ProfileContent> {
        self.inner.profile_content()
    }

    pub fn policy_rule_room_content(&self) -> Option<PolicyRuleRoomContent> {
        self.inner.policy_rule_room_content()
    }

    pub fn policy_rule_server_content(&self) -> Option<PolicyRuleServerContent> {
        self.inner.policy_rule_server_content()
    }

    pub fn policy_rule_user_content(&self) -> Option<PolicyRuleUserContent> {
        self.inner.policy_rule_user_content()
    }

    pub fn room_avatar_content(&self) -> Option<RoomAvatarContent> {
        self.inner.room_avatar_content()
    }

    pub fn room_create_content(&self) -> Option<RoomCreateContent> {
        self.inner.room_create_content()
    }

    pub fn room_encryption_content(&self) -> Option<RoomEncryptionContent> {
        self.inner.room_encryption_content()
    }

    pub fn room_guest_access_content(&self) -> Option<RoomGuestAccessContent> {
        self.inner.room_guest_access_content()
    }

    pub fn room_history_visibility_content(&self) -> Option<RoomHistoryVisibilityContent> {
        self.inner.room_history_visibility_content()
    }

    pub fn room_join_rules_content(&self) -> Option<RoomJoinRulesContent> {
        self.inner.room_join_rules_content()
    }

    pub fn room_name_content(&self) -> Option<RoomNameContent> {
        self.inner.room_name_content()
    }

    pub fn room_pinned_events_content(&self) -> Option<RoomPinnedEventsContent> {
        self.inner.room_pinned_events_content()
    }

    pub fn room_power_levels_content(&self) -> Option<RoomPowerLevelsContent> {
        self.inner.room_power_levels_content()
    }

    pub fn room_server_acl_content(&self) -> Option<RoomServerAclContent> {
        self.inner.room_server_acl_content()
    }

    pub fn room_tombstone_content(&self) -> Option<RoomTombstoneContent> {
        self.inner.room_tombstone_content()
    }

    pub fn room_topic_content(&self) -> Option<RoomTopicContent> {
        self.inner.room_topic_content()
    }

    pub fn space_child_content(&self) -> Option<SpaceChildContent> {
        self.inner.space_child_content()
    }

    pub fn space_parent_content(&self) -> Option<SpaceParentContent> {
        self.inner.space_parent_content()
    }

    pub fn mentions_you(&self) -> bool {
        let Ok(user_id) = self.client.user_id() else {
            return false;
        };
        self.inner.whom().contains(&user_id.to_string())
    }
}

impl Deref for Activity {
    type Target = CoreActivity;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

#[derive(Debug, Clone)]
pub struct Activities {
    index: IndexKey,
    client: Client,
}

impl Activities {
    pub async fn get_ids(&self, offset: u32, limit: u32) -> anyhow::Result<Vec<String>> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                anyhow::Ok(
                    me.iter()
                        .await?
                        .map(|e| e.event_meta().event_id.to_string())
                        .skip(offset as usize)
                        .take(limit as usize)
                        .collect()
                        .await,
                )
            })
            .await?
    }

    pub async fn iter(&self) -> anyhow::Result<impl Stream<Item = CoreActivity> + '_> {
        let store = self.client.store();
        Ok(
            futures::stream::iter(self.client.store().get_list(&self.index).await?)
                .filter_map(|a| async { CoreActivity::for_acter_model(store, a).await.ok() }),
        )
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|f| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        self.client.subscribe(self.index.clone())
    }
}

impl Client {
    pub async fn activity(&self, key: String) -> anyhow::Result<Activity> {
        let ev_id = EventId::parse(key)?;
        let client = self.clone();

        Ok(RUNTIME
            .spawn(async move {
                client
                    .core
                    .activity(&ev_id)
                    .await
                    .map(|inner| Activity { inner, client })
            })
            .await??)
    }

    pub fn activities_for_room(&self, room_id: String) -> anyhow::Result<Activities> {
        Ok(Activities {
            index: IndexKey::RoomHistory(RoomId::parse(room_id)?),
            client: self.clone(),
        })
    }
    pub fn activities_for_obj(&self, object_id: String) -> anyhow::Result<Activities> {
        Ok(Activities {
            index: IndexKey::ObjectHistory(EventId::parse(object_id)?),
            client: self.clone(),
        })
    }
}
