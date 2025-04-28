use chrono::{NaiveDate, NaiveTime, Utc};
use matrix_sdk::ruma::{events::room::message::TextMessageEventContent, OwnedEventId, OwnedUserId};
use object::ActivityObject;
use urlencoding::encode;

use crate::{
    client::CoreClient,
    events::{
        attachments::AttachmentContent, news::NewsContent, rsvp::RsvpStatus, RefDetails,
        UtcDateTime,
    },
    models::{
        status::{
            MembershipContent, PolicyRuleRoomContent, PolicyRuleServerContent,
            PolicyRuleUserContent, ProfileContent, RoomAvatarContent, RoomCreateContent,
            RoomEncryptionContent, RoomGuestAccessContent, RoomHistoryVisibilityContent,
            RoomJoinRulesContent, RoomNameContent, RoomPinnedEventsContent, RoomPowerLevelsContent,
            RoomServerAclContent, RoomTombstoneContent, RoomTopicContent, SpaceChildContent,
        },
        ActerModel, ActerSupportedRoomStatusEvents, AnyActerModel, EventMeta,
    },
    store::Store,
};

pub mod object;
pub mod status;

#[derive(Clone, Debug)]
pub enum ActivityContent {
    MembershipChange(MembershipContent),
    ProfileChange(ProfileContent),
    PolicyRuleRoom(PolicyRuleRoomContent),
    PolicyRuleServer(PolicyRuleServerContent),
    PolicyRuleUser(PolicyRuleUserContent),
    RoomAvatar(RoomAvatarContent),
    RoomCreate(RoomCreateContent),
    RoomEncryption(RoomEncryptionContent),
    RoomGuestAccess(RoomGuestAccessContent),
    RoomHistoryVisibility(RoomHistoryVisibilityContent),
    RoomJoinRules(RoomJoinRulesContent),
    RoomName(RoomNameContent),
    RoomPinnedEvents(RoomPinnedEventsContent),
    RoomPowerLevels(RoomPowerLevelsContent),
    RoomServerAcl(RoomServerAclContent),
    RoomTombstone(RoomTombstoneContent),
    RoomTopic(RoomTopicContent),
    SpaceChild(SpaceChildContent),
    Boost {
        first_slide: Option<NewsContent>,
    },
    Attachment {
        object: ActivityObject,
        content: AttachmentContent,
    },
    Reference {
        object: ActivityObject,
        details: RefDetails,
    },
    Comment {
        object: ActivityObject,
        content: TextMessageEventContent,
    },
    Reaction {
        object: ActivityObject,
        key: String,
    },
    Creation {
        object: ActivityObject,
    },
    TitleChange {
        object: ActivityObject,
        new_title: String,
    },
    DescriptionChange {
        object: ActivityObject,
        content: Option<TextMessageEventContent>,
    },
    // event specific
    EventDateChange {
        object: ActivityObject,
        new_date: UtcDateTime,
    },
    // event specific
    Rsvp {
        object: ActivityObject,
        rsvp: RsvpStatus,
    },
    // tasks and task list specific
    TaskAdd {
        object: ActivityObject,
        task_title: String,
    },
    TaskProgress {
        object: ActivityObject,
        done: bool,
    },
    TaskDueDateChange {
        object: ActivityObject,
        new_due_date: Option<NaiveDate>,
    },
    TaskAccept {
        object: ActivityObject,
    },
    TaskDecline {
        object: ActivityObject,
    },
    ObjectInvitation {
        object: ActivityObject,
        invitees: Vec<OwnedUserId>,
    },
    OtherChanges {
        object: ActivityObject,
    },
}

#[derive(Clone, Debug)]
pub struct Activity {
    inner: ActivityContent,
    meta: EventMeta,
}

impl Activity {
    fn new(meta: EventMeta, inner: ActivityContent) -> Self {
        Self { meta, inner }
    }
    pub fn content(&self) -> &ActivityContent {
        &self.inner
    }

    // attachment and other might have internal subtypes
    pub fn sub_type_str(&self) -> Option<String> {
        match &self.inner {
            ActivityContent::Attachment { content, .. } => Some(content.type_str()),
            _ => None,
        }
    }

    pub fn name(&self) -> Option<String> {
        self.title()
    }

    pub fn type_str(&self) -> String {
        match &self.inner {
            ActivityContent::MembershipChange(c) => {
                return c.change();
            }
            ActivityContent::ProfileChange(c) => {
                if c.display_name_change().is_some() {
                    "displayName"
                } else if c.avatar_url_change().is_some() {
                    "avatarUrl"
                } else {
                    unreachable!()
                }
            }
            ActivityContent::PolicyRuleRoom(_) => "policyRuleRoom",
            ActivityContent::PolicyRuleServer(_) => "policyRuleServer",
            ActivityContent::PolicyRuleUser(_) => "policyRuleUser",
            ActivityContent::RoomAvatar(_) => "roomAvatar",
            ActivityContent::RoomCreate(_) => "roomCreate",
            ActivityContent::RoomEncryption(_) => "roomEncryption",
            ActivityContent::RoomGuestAccess(_) => "roomGuestAccess",
            ActivityContent::RoomHistoryVisibility(_) => "roomHistoryVisibility",
            ActivityContent::RoomJoinRules(_) => "roomJoinRules",
            ActivityContent::RoomName(_) => "roomName",
            ActivityContent::RoomPinnedEvents(_) => "roomPinnedEvents",
            ActivityContent::RoomPowerLevels(_) => "roomPowerLevels",
            ActivityContent::RoomServerAcl(_) => "roomServerAcl",
            ActivityContent::RoomTombstone(_) => "roomTombstone",
            ActivityContent::RoomTopic(_) => "roomTopic",
            ActivityContent::SpaceChild(_) => "spaceChild",
            ActivityContent::Comment { .. } => "comment",
            ActivityContent::Reaction { .. } => "reaction",
            ActivityContent::Attachment { .. } => "attachment",
            ActivityContent::Reference { .. } => "references",
            ActivityContent::TaskProgress { done, .. } => {
                if *done {
                    "taskComplete"
                } else {
                    "taskReOpen"
                }
            }
            ActivityContent::TaskDueDateChange { .. } => "taskDueDateChange",
            ActivityContent::TaskAccept { .. } => "taskAccept",
            ActivityContent::TaskDecline { .. } => "taskDecline",
            ActivityContent::Boost { .. } => "news",
            ActivityContent::Creation { .. } => "creation",
            ActivityContent::TitleChange { .. } => "titleChange",
            ActivityContent::DescriptionChange { .. } => "descriptionChange",
            ActivityContent::EventDateChange { .. } => "eventDateChange",

            ActivityContent::Rsvp { rsvp, .. } => match rsvp {
                RsvpStatus::Yes => "rsvpYes",
                RsvpStatus::Maybe => "rsvpMaybe",
                RsvpStatus::No => "rsvpNo",
            },
            ActivityContent::TaskAdd { .. } => "taskAdd",
            ActivityContent::ObjectInvitation { .. } => "objectInvitation",
            ActivityContent::OtherChanges { .. } => "otherChanges",
        }
        .to_owned()
    }

    pub fn membership_content(&self) -> Option<MembershipContent> {
        if let ActivityContent::MembershipChange(c) = &self.inner {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn profile_content(&self) -> Option<ProfileContent> {
        if let ActivityContent::ProfileChange(c) = &self.inner {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn event_meta(&self) -> &EventMeta {
        &self.meta
    }

    pub fn title(&self) -> Option<String> {
        match &self.inner {
            ActivityContent::Attachment { content, .. } => content.name(),
            ActivityContent::TaskAdd { task_title, .. } => Some(task_title.clone()),
            _ => None,
        }
    }

    pub fn room_avatar(&self) -> Option<String> {
        match &self.inner {
            ActivityContent::RoomAvatar(c) => c.url_new_val(),
            _ => None,
        }
    }

    pub fn room_name(&self) -> Option<String> {
        match &self.inner {
            ActivityContent::RoomName(c) => Some(c.new_val()),
            _ => None,
        }
    }

    pub fn room_topic(&self) -> Option<String> {
        match &self.inner {
            ActivityContent::RoomTopic(c) => Some(c.new_val()),
            _ => None,
        }
    }

    pub fn object(&self) -> Option<ActivityObject> {
        match &self.inner {
            ActivityContent::MembershipChange(_)
            | ActivityContent::ProfileChange(_)
            | ActivityContent::PolicyRuleRoom(_)
            | ActivityContent::PolicyRuleServer(_)
            | ActivityContent::PolicyRuleUser(_)
            | ActivityContent::RoomAvatar(_)
            | ActivityContent::RoomCreate(_)
            | ActivityContent::RoomEncryption(_)
            | ActivityContent::RoomGuestAccess(_)
            | ActivityContent::RoomHistoryVisibility(_)
            | ActivityContent::RoomJoinRules(_)
            | ActivityContent::RoomName(_)
            | ActivityContent::RoomPinnedEvents(_)
            | ActivityContent::RoomPowerLevels(_)
            | ActivityContent::RoomServerAcl(_)
            | ActivityContent::RoomTombstone(_)
            | ActivityContent::RoomTopic(_)
            | ActivityContent::SpaceChild(_) => None,

            ActivityContent::Boost { .. } => None,

            ActivityContent::Attachment { object, .. }
            | ActivityContent::Reference { object, .. }
            | ActivityContent::Comment { object, .. }
            | ActivityContent::Reaction { object, .. }
            | ActivityContent::Creation { object }
            | ActivityContent::TitleChange { object, .. }
            | ActivityContent::DescriptionChange { object, .. }
            | ActivityContent::EventDateChange { object, .. }
            | ActivityContent::OtherChanges { object }
            | ActivityContent::Rsvp { object, .. }
            | ActivityContent::TaskAdd { object, .. }
            | ActivityContent::TaskProgress { object, .. }
            | ActivityContent::TaskDueDateChange { object, .. }
            | ActivityContent::TaskAccept { object }
            | ActivityContent::TaskDecline { object }
            | ActivityContent::ObjectInvitation { object, .. } => Some(object.clone()),
        }
    }

    pub fn reaction_key(&self) -> Option<String> {
        if let ActivityContent::Reaction { key, .. } = &self.inner {
            Some(key.clone())
        } else {
            None
        }
    }

    pub fn new_date(&self) -> Option<UtcDateTime> {
        match &self.inner {
            &ActivityContent::EventDateChange { new_date, .. } => Some(new_date),
            ActivityContent::TaskDueDateChange {
                new_due_date: Some(new_due_date),
                ..
            } => Some(UtcDateTime::from_naive_utc_and_offset(
                new_due_date.and_time(
                    NaiveTime::from_num_seconds_from_midnight_opt(0, 0).expect("midnight exists"),
                ),
                Utc,
            )),
            _ => None,
        }
    }

    pub fn ref_details(&self) -> Option<RefDetails> {
        if let ActivityContent::Reference { details, .. } = &self.inner {
            Some(details.clone())
        } else {
            None
        }
    }

    pub fn target_url(&self) -> String {
        match &self.inner {
            ActivityContent::Boost { .. } => format!("/updates/{}", self.meta.event_id),
            ActivityContent::TitleChange { object, .. }
            | ActivityContent::DescriptionChange { object, .. }
            | ActivityContent::EventDateChange { object, .. }
            | ActivityContent::Rsvp { object, .. }
            | ActivityContent::TaskProgress { object, .. }
            | ActivityContent::TaskDueDateChange { object, .. }
            | ActivityContent::TaskAccept { object, .. }
            | ActivityContent::TaskDecline { object, .. }
            | ActivityContent::OtherChanges { object }
            | ActivityContent::Creation { object, .. }
            | ActivityContent::ObjectInvitation { object, .. } => object.target_url(),

            ActivityContent::Attachment { object, .. } => format!(
                "{}?section=attachments&attachmentId={}",
                object.target_url(),
                encode(self.meta.event_id.as_str()),
            ),
            ActivityContent::Reference { object, .. } => format!(
                "{}?section=references&referenceId={}",
                object.target_url(),
                encode(self.meta.event_id.as_str()),
            ),
            ActivityContent::Comment { object, .. } => format!(
                "{}?section=comments&commentId={}",
                object.target_url(),
                encode(self.meta.event_id.as_str()),
            ),
            ActivityContent::Reaction { object, .. } => format!(
                "{}?section=reactions&reactionId={}",
                object.target_url(),
                encode(self.meta.event_id.as_str()),
            ),

            ActivityContent::TaskAdd { object, .. } => {
                format!("/tasks/{}/{}", object.object_id_str(), self.meta.event_id)
            }
            ActivityContent::MembershipChange(_)
            | ActivityContent::ProfileChange(_)
            | ActivityContent::PolicyRuleRoom(_)
            | ActivityContent::PolicyRuleServer(_)
            | ActivityContent::PolicyRuleUser(_)
            | ActivityContent::RoomAvatar(_)
            | ActivityContent::RoomCreate(_)
            | ActivityContent::RoomEncryption(_)
            | ActivityContent::RoomGuestAccess(_)
            | ActivityContent::RoomHistoryVisibility(_)
            | ActivityContent::RoomJoinRules(_)
            | ActivityContent::RoomName(_)
            | ActivityContent::RoomPinnedEvents(_)
            | ActivityContent::RoomPowerLevels(_)
            | ActivityContent::RoomServerAcl(_)
            | ActivityContent::RoomTombstone(_)
            | ActivityContent::RoomTopic(_)
            | ActivityContent::SpaceChild(_) => todo!(),
        }
    }

    pub fn whom(&self) -> Vec<String> {
        let ActivityContent::ObjectInvitation { ref invitees, .. } = self.content() else {
            return vec![];
        };
        invitees
            .iter()
            .map(ToString::to_string)
            .collect::<Vec<String>>()
    }

    pub fn task_list_id_str(&self) -> Option<String> {
        match &self.inner {
            ActivityContent::TaskAccept { object }
            | ActivityContent::TaskAdd { object, .. }
            | ActivityContent::TaskDecline { object }
            | ActivityContent::TaskDueDateChange { object, .. }
            | ActivityContent::TaskProgress { object, .. } => object.task_list_id_str(),
            _ => None,
        }
    }
}

impl Activity {
    pub async fn for_acter_model(store: &Store, mdl: AnyActerModel) -> Result<Self, crate::Error> {
        let meta = mdl.event_meta().clone();
        match mdl {
            AnyActerModel::RoomStatus(s) => match s.inner {
                ActerSupportedRoomStatusEvents::MembershipChange(c) => {
                    Ok(Self::new(meta, ActivityContent::MembershipChange(c)))
                }
                ActerSupportedRoomStatusEvents::ProfileChange(c) => {
                    Ok(Self::new(meta, ActivityContent::ProfileChange(c)))
                }
                ActerSupportedRoomStatusEvents::PolicyRuleRoom(c) => {
                    Ok(Self::new(meta, ActivityContent::PolicyRuleRoom(c)))
                }
                ActerSupportedRoomStatusEvents::PolicyRuleServer(c) => {
                    Ok(Self::new(meta, ActivityContent::PolicyRuleServer(c)))
                }
                ActerSupportedRoomStatusEvents::PolicyRuleUser(c) => {
                    Ok(Self::new(meta, ActivityContent::PolicyRuleUser(c)))
                }
                ActerSupportedRoomStatusEvents::RoomAvatar(c) => {
                    Ok(Self::new(meta, ActivityContent::RoomAvatar(c)))
                }
                ActerSupportedRoomStatusEvents::RoomCreate(c) => {
                    Ok(Self::new(meta, ActivityContent::RoomCreate(c)))
                }
                ActerSupportedRoomStatusEvents::RoomEncryption(c) => {
                    Ok(Self::new(meta, ActivityContent::RoomEncryption(c)))
                }
                ActerSupportedRoomStatusEvents::RoomGuestAccess(c) => {
                    Ok(Self::new(meta, ActivityContent::RoomGuestAccess(c)))
                }
                ActerSupportedRoomStatusEvents::RoomHistoryVisibility(c) => {
                    Ok(Self::new(meta, ActivityContent::RoomHistoryVisibility(c)))
                }
                ActerSupportedRoomStatusEvents::RoomJoinRules(c) => {
                    Ok(Self::new(meta, ActivityContent::RoomJoinRules(c)))
                }
                ActerSupportedRoomStatusEvents::RoomName(c) => {
                    Ok(Self::new(meta, ActivityContent::RoomName(c)))
                }
                ActerSupportedRoomStatusEvents::RoomPinnedEvents(c) => {
                    Ok(Self::new(meta, ActivityContent::RoomPinnedEvents(c)))
                }
                ActerSupportedRoomStatusEvents::RoomPowerLevels(c) => {
                    Ok(Self::new(meta, ActivityContent::RoomPowerLevels(c)))
                }
                ActerSupportedRoomStatusEvents::RoomServerAcl(c) => {
                    Ok(Self::new(meta, ActivityContent::RoomServerAcl(c)))
                }
                ActerSupportedRoomStatusEvents::RoomTombstone(c) => {
                    Ok(Self::new(meta, ActivityContent::RoomTombstone(c)))
                }
                ActerSupportedRoomStatusEvents::RoomTopic(c) => {
                    Ok(Self::new(meta, ActivityContent::RoomTopic(c)))
                }
                ActerSupportedRoomStatusEvents::SpaceChild(c) => {
                    Ok(Self::new(meta, ActivityContent::SpaceChild(c)))
                }
            },

            AnyActerModel::NewsEntry(n) => {
                let first_slide = n.slides.first().map(|a| a.content().clone());
                Ok(Self::new(meta, ActivityContent::Boost { first_slide }))
            }
            AnyActerModel::Comment(e) => {
                let object = store
                    .get(&e.inner.on.event_id)
                    .await
                    .map_err(|error| {
                        tracing::error!(?error, "Error loading parent of comment");
                    })
                    .ok()
                    .and_then(|o| ActivityObject::try_from(&o).ok())
                    .unwrap_or_else(|| ActivityObject::Unknown {
                        object_id: e.inner.on.event_id.to_owned(),
                    });
                Ok(Self::new(
                    meta,
                    ActivityContent::Comment {
                        object,
                        content: e.content.clone(),
                    },
                ))
            }
            AnyActerModel::Attachment(e) => {
                let object = store
                    .get(&e.inner.on.event_id)
                    .await
                    .map_err(|error| {
                        tracing::error!(?error, "Error loading parent of comment");
                    })
                    .ok()
                    .and_then(|o| ActivityObject::try_from(&o).ok())
                    .unwrap_or_else(|| ActivityObject::Unknown {
                        object_id: e.inner.on.event_id.to_owned(),
                    });

                if let AttachmentContent::Reference(details) = e.inner.content {
                    Ok(Self::new(
                        meta,
                        ActivityContent::Reference { object, details },
                    ))
                } else {
                    Ok(Self::new(
                        meta,
                        ActivityContent::Attachment {
                            object,
                            content: e.inner.content,
                        },
                    ))
                }
            }

            AnyActerModel::Reaction(e) => {
                let object = store
                    .get(&e.inner.relates_to.event_id)
                    .await
                    .map_err(|error| {
                        tracing::error!(?error, "Error loading parent of reaction");
                    })
                    .ok()
                    .and_then(|o| ActivityObject::try_from(&o).ok())
                    .unwrap_or_else(|| ActivityObject::Unknown {
                        object_id: e.inner.relates_to.event_id.to_owned(),
                    });
                Ok(Self::new(
                    meta,
                    ActivityContent::Reaction {
                        object,
                        key: e.inner.relates_to.key,
                    },
                ))
            }

            AnyActerModel::ExplicitInvite(e) => {
                let object = store
                    .get(&e.inner.to.event_id)
                    .await
                    .map_err(|error| {
                        tracing::error!(?error, "Error loading parent of reaction");
                    })
                    .ok()
                    .and_then(|o| ActivityObject::try_from(&o).ok())
                    .unwrap_or_else(|| ActivityObject::Unknown {
                        object_id: e.inner.to.event_id.to_owned(),
                    });
                Ok(Self::new(
                    meta,
                    ActivityContent::ObjectInvitation {
                        object,
                        invitees: e.inner.mention.user_ids.into_iter().collect(),
                    },
                ))
            }

            // -- Pin
            AnyActerModel::Pin(e) => {
                let object = ActivityObject::Pin {
                    object_id: e.event_id().to_owned(),
                    title: e.title.clone(),
                };
                Ok(Self::new(meta, ActivityContent::Creation { object }))
            }

            AnyActerModel::PinUpdate(e) => {
                let object = store
                    .get(&e.inner.pin.event_id)
                    .await
                    .map_err(|error| {
                        tracing::error!(?error, "Error loading parent of comment");
                    })
                    .ok()
                    .and_then(|o| ActivityObject::try_from(&o).ok())
                    .unwrap_or_else(|| ActivityObject::Unknown {
                        object_id: e.inner.pin.event_id.to_owned(),
                    });

                if let Some(new_title) = e.inner.title {
                    Ok(Self::new(
                        meta,
                        ActivityContent::TitleChange { object, new_title },
                    ))
                } else if let Some(Some(new_content)) = e.inner.content {
                    return Ok(Self::new(
                        meta,
                        ActivityContent::DescriptionChange {
                            object,
                            content: Some(new_content),
                        },
                    ));
                } else {
                    // fallback: other changes
                    return Ok(Self::new(meta, ActivityContent::OtherChanges { object }));
                }
            }

            // ---- Event
            AnyActerModel::CalendarEvent(e) => {
                let object = ActivityObject::CalendarEvent {
                    object_id: e.event_id().to_owned(),
                    title: e.inner.title,
                };
                Ok(Self::new(meta, ActivityContent::Creation { object }))
            }

            AnyActerModel::CalendarEventUpdate(e) => {
                let object = store
                    .get(&e.inner.calendar_event.event_id)
                    .await
                    .map_err(|error| {
                        tracing::error!(?error, "Error loading parent of comment");
                    })
                    .ok()
                    .and_then(|o| ActivityObject::try_from(&o).ok())
                    .unwrap_or_else(|| ActivityObject::Unknown {
                        object_id: e.inner.calendar_event.event_id.to_owned(),
                    });

                if let Some(new_title) = e.inner.title {
                    Ok(Self::new(
                        meta,
                        ActivityContent::TitleChange { object, new_title },
                    ))
                } else if let Some(Some(new_content)) = e.inner.description {
                    Ok(Self::new(
                        meta,
                        ActivityContent::DescriptionChange {
                            object,
                            content: Some(new_content),
                        },
                    ))
                } else if let Some(new_date) = e.inner.utc_start {
                    Ok(Self::new(
                        meta,
                        ActivityContent::EventDateChange { object, new_date },
                    ))
                } else if let Some(new_date) = e.inner.utc_end {
                    Ok(Self::new(
                        meta,
                        ActivityContent::EventDateChange { object, new_date },
                    ))
                } else {
                    // fallback: other changes
                    return Ok(Self::new(meta, ActivityContent::OtherChanges { object }));
                }
            }

            // ---- Event
            AnyActerModel::Rsvp(e) => {
                let object = store
                    .get(&e.inner.to.event_id)
                    .await
                    .map_err(|error| {
                        tracing::error!(?error, "Error loading parent of comment");
                    })
                    .ok()
                    .and_then(|o| ActivityObject::try_from(&o).ok())
                    .unwrap_or_else(|| ActivityObject::Unknown {
                        object_id: e.inner.to.event_id.to_owned(),
                    });

                Ok(Self::new(
                    meta,
                    ActivityContent::Rsvp {
                        object,
                        rsvp: e.inner.status,
                    },
                ))
            }

            // --- Task lists
            AnyActerModel::TaskList(e) => {
                let object = ActivityObject::TaskList {
                    object_id: e.event_id().to_owned(),
                    title: e.inner.name,
                };
                Ok(Self::new(meta, ActivityContent::Creation { object }))
            }

            AnyActerModel::TaskListUpdate(e) => {
                let object = store
                    .get(&e.inner.task_list.event_id)
                    .await
                    .map_err(|error| {
                        tracing::error!(?error, "Error loading parent of comment");
                    })
                    .ok()
                    .and_then(|o| ActivityObject::try_from(&o).ok())
                    .unwrap_or_else(|| ActivityObject::Unknown {
                        object_id: e.inner.task_list.event_id.to_owned(),
                    });

                if let Some(new_title) = e.inner.name {
                    Ok(Self::new(
                        meta,
                        ActivityContent::TitleChange { object, new_title },
                    ))
                } else if let Some(Some(new_content)) = e.inner.description {
                    Ok(Self::new(
                        meta,
                        ActivityContent::DescriptionChange {
                            object,
                            content: Some(new_content),
                        },
                    ))
                } else {
                    // fallback: other changes
                    Ok(Self::new(meta, ActivityContent::OtherChanges { object }))
                }
            }
            // -- Task Specific
            AnyActerModel::Task(e) => {
                let object = store
                    .get(&e.inner.task_list_id.event_id)
                    .await
                    .map_err(|error| {
                        tracing::error!(?error, "Error loading parent of comment");
                    })
                    .ok()
                    .and_then(|o| ActivityObject::try_from(&o).ok())
                    .unwrap_or_else(|| ActivityObject::Unknown {
                        object_id: e.inner.task_list_id.event_id.to_owned(),
                    });

                Ok(Self::new(
                    meta,
                    ActivityContent::TaskAdd {
                        object,
                        task_title: e.inner.title,
                    },
                ))
            }
            AnyActerModel::TaskUpdate(e) => {
                let object = store
                    .get(&e.inner.task.event_id)
                    .await
                    .map_err(|error| {
                        tracing::error!(?error, "Error loading parent of comment");
                    })
                    .ok()
                    .and_then(|o| ActivityObject::try_from(&o).ok())
                    .unwrap_or_else(|| ActivityObject::Unknown {
                        object_id: e.inner.task.event_id.to_owned(),
                    });

                if let Some(new_percent) = e.inner.progress_percent {
                    Ok(Self::new(
                        meta,
                        ActivityContent::TaskProgress {
                            object,
                            done: new_percent
                                .map(|percent| percent >= 100)
                                .unwrap_or_default(),
                        },
                    ))
                } else if let Some(due_date) = e.inner.due_date {
                    Ok(Self::new(
                        meta,
                        ActivityContent::TaskDueDateChange {
                            object,
                            new_due_date: due_date,
                        },
                    ))
                } else if let Some(new_title) = e.inner.title {
                    Ok(Self::new(
                        meta,
                        ActivityContent::TitleChange { object, new_title },
                    ))
                } else if let Some(Some(new_content)) = e.inner.description {
                    return Ok(Self::new(
                        meta,
                        ActivityContent::DescriptionChange {
                            object,
                            content: Some(new_content),
                        },
                    ));
                } else {
                    // fallback: other changes
                    return Ok(Self::new(meta, ActivityContent::OtherChanges { object }));
                }
            }
            AnyActerModel::TaskSelfAssign(e) => {
                let object = store
                    .get(&e.inner.task.event_id)
                    .await
                    .map_err(|error| {
                        tracing::error!(?error, "Error loading parent of comment");
                    })
                    .ok()
                    .and_then(|o| ActivityObject::try_from(&o).ok())
                    .unwrap_or_else(|| ActivityObject::Unknown {
                        object_id: e.inner.task.event_id.to_owned(),
                    });

                Ok(Self::new(meta, ActivityContent::TaskAccept { object }))
            }

            AnyActerModel::TaskSelfUnassign(e) => {
                let object = store
                    .get(&e.inner.task.event_id)
                    .await
                    .map_err(|error| {
                        tracing::error!(?error, "Error loading parent of comment");
                    })
                    .ok()
                    .and_then(|o| ActivityObject::try_from(&o).ok())
                    .unwrap_or_else(|| ActivityObject::Unknown {
                        object_id: e.inner.task.event_id.to_owned(),
                    });

                Ok(Self::new(meta, ActivityContent::TaskDecline { object }))
            }
            AnyActerModel::RedactedActerModel(_)
            | AnyActerModel::NewsEntryUpdate(_)
            | AnyActerModel::Story(_)
            | AnyActerModel::StoryUpdate(_)
            | AnyActerModel::CommentUpdate(_)
            | AnyActerModel::AttachmentUpdate(_)
            | AnyActerModel::ReadReceipt(_) => Err(crate::Error::Custom(
                "Converting model into activity not yet supported".to_string(),
            )),
            #[cfg(any(test, feature = "testing"))]
            AnyActerModel::TestModel(_) => todo!(),
        }
    }
}

impl CoreClient {
    pub async fn activity(&self, key: &OwnedEventId) -> crate::Result<Activity> {
        let model = self.store.get(key).await?;
        Activity::for_acter_model(&self.store, model).await
    }
}
