use super::attachments::{Attachment, AttachmentUpdate};
use super::calendar::{CalendarEvent, CalendarEventUpdate};
use super::capabilities::Capability;
use super::comments::{Comment, CommentUpdate};
use super::conversion::ParseError;
pub(crate) use super::execution::transition_tree;
use super::meta::EventMeta;
use super::news::{NewsEntry, NewsEntryUpdate};
use super::pins::{Pin, PinUpdate};
use super::reactions::Reaction;
use super::read_receipts::ReadReceipt;
use super::redaction::RedactedActerModel;
use super::rsvp::Rsvp;
use super::stories::{Story, StoryUpdate};
use super::tasks::{Task, TaskList, TaskListUpdate, TaskSelfAssign, TaskSelfUnassign, TaskUpdate};
use core::fmt::Debug;
use enum_dispatch::enum_dispatch;
use matrix_sdk_base::ruma::{
    events::{reaction::ReactionEventContent, StaticEventContent},
    EventId, OwnedEventId, RoomId, UserId,
};
use serde::{Deserialize, Serialize};
use tracing::{error, trace, warn};

#[cfg(any(test, feature = "testing"))]
use super::test::TestModel;

use crate::store::Store;
use crate::{
    events::{
        attachments::{AttachmentEventContent, AttachmentUpdateEventContent},
        calendar::{CalendarEventEventContent, CalendarEventUpdateEventContent},
        comments::{CommentEventContent, CommentUpdateEventContent},
        news::{NewsEntryEventContent, NewsEntryUpdateEventContent},
        pins::{PinEventContent, PinUpdateEventContent},
        read_receipt::ReadReceiptEventContent,
        rsvp::RsvpEventContent,
        stories::{StoryEventContent, StoryUpdateEventContent},
        tasks::{
            TaskEventContent, TaskListEventContent, TaskListUpdateEventContent,
            TaskSelfAssignEventContent, TaskSelfUnassignEventContent, TaskUpdateEventContent,
        },
        AnyActerEvent,
    },
    executor::Executor,
    referencing::{ExecuteReference, IndexKey},
};

#[enum_dispatch(AnyActerModel)]
pub trait ActerModel: Debug {
    /// the event metadata for this model
    fn event_meta(&self) -> &EventMeta;

    fn indizes(&self, user_id: &UserId) -> Vec<IndexKey>;

    /// The key to store this model under
    fn event_id(&self) -> &EventId {
        &self.event_meta().event_id
    }

    /// The room id this model belongs to
    fn room_id(&self) -> &RoomId {
        &self.event_meta().room_id
    }

    /// The models to inform about this model as it belongs to that
    fn belongs_to(&self) -> Option<Vec<OwnedEventId>> {
        None
    }

    /// activate to enable commenting support for this type of model
    fn capabilities(&self) -> &[Capability] {
        &[]
    }
    /// The execution to run when this model is found.
    async fn execute(self, store: &Store) -> crate::Result<Vec<ExecuteReference>>;

    /// handle transition from an external Item upon us
    fn transition(&mut self, model: &AnyActerModel) -> crate::Result<bool> {
        warn!(?self, ?model, "Transition has not been implemented");
        Ok(false)
    }
    /// The execution to run when this model is found.
    async fn redact(
        &self,
        store: &Store,
        redaction_model: RedactedActerModel,
    ) -> crate::Result<Vec<ExecuteReference>> {
        trace!(event_id=?redaction_model.event_id(), ?redaction_model, "handling");
        let Some(belongs_to) = self.belongs_to() else {
            let event_id = redaction_model.event_id();
            trace!(?event_id, "saving simple model");
            return store.save(redaction_model.into()).await;
        };
        let model: AnyActerModel = redaction_model.into();
        trace!(event_id=?model.event_id(), ?belongs_to, "transitioning tree");
        let mut models = transition_tree(store, belongs_to, &model).await?;
        models.push(model);
        store.save_many(models).await
    }
}

#[enum_dispatch]
#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum AnyActerModel {
    RedactedActerModel,

    // -- Calendar
    CalendarEvent(CalendarEvent),
    CalendarEventUpdate(CalendarEventUpdate),

    // -- Tasks
    TaskList(TaskList),
    TaskListUpdate(TaskListUpdate),
    Task(Task),
    TaskUpdate(TaskUpdate),
    TaskSelfAssign(TaskSelfAssign),
    TaskSelfUnassign(TaskSelfUnassign),

    // -- Pins
    Pin(Pin),
    PinUpdate(PinUpdate),

    // -- News
    NewsEntry(NewsEntry),
    NewsEntryUpdate(NewsEntryUpdate),

    // -- News
    Story(Story),
    StoryUpdate(StoryUpdate),

    // -- more generics
    Comment(Comment),
    CommentUpdate(CommentUpdate),

    Attachment(Attachment),
    AttachmentUpdate(AttachmentUpdate),

    Rsvp(Rsvp),
    Reaction(Reaction),
    ReadReceipt(ReadReceipt),

    #[cfg(any(test, feature = "testing"))]
    TestModel(TestModel),
}

impl AnyActerModel {
    pub fn model_type(&self) -> &str {
        match self {
            AnyActerModel::CalendarEvent(_) => CalendarEventEventContent::TYPE,
            AnyActerModel::CalendarEventUpdate(_) => CalendarEventUpdateEventContent::TYPE,
            AnyActerModel::TaskList(_) => TaskListEventContent::TYPE,
            AnyActerModel::TaskListUpdate(_) => TaskListUpdateEventContent::TYPE,
            AnyActerModel::Task(_) => TaskEventContent::TYPE,
            AnyActerModel::TaskUpdate(_) => TaskUpdateEventContent::TYPE,
            AnyActerModel::TaskSelfAssign(_) => TaskSelfAssignEventContent::TYPE,
            AnyActerModel::TaskSelfUnassign(_) => TaskSelfUnassignEventContent::TYPE,
            AnyActerModel::Pin(_) => PinEventContent::TYPE,
            AnyActerModel::PinUpdate(_) => PinUpdateEventContent::TYPE,
            AnyActerModel::NewsEntry(_) => NewsEntryEventContent::TYPE,
            AnyActerModel::NewsEntryUpdate(_) => NewsEntryUpdateEventContent::TYPE,
            AnyActerModel::Story(_) => StoryEventContent::TYPE,
            AnyActerModel::StoryUpdate(_) => StoryUpdateEventContent::TYPE,
            AnyActerModel::Comment(_) => CommentEventContent::TYPE,
            AnyActerModel::CommentUpdate(_) => CommentUpdateEventContent::TYPE,
            AnyActerModel::Attachment(_) => AttachmentEventContent::TYPE,
            AnyActerModel::AttachmentUpdate(_) => AttachmentUpdateEventContent::TYPE,
            AnyActerModel::Rsvp(_) => RsvpEventContent::TYPE,
            AnyActerModel::Reaction(_) => ReactionEventContent::TYPE,
            AnyActerModel::ReadReceipt(_) => ReadReceiptEventContent::TYPE,
            AnyActerModel::RedactedActerModel(..) => "unknown_redacted_model",
            #[cfg(any(test, feature = "testing"))]
            AnyActerModel::TestModel(_) => "test_model",
        }
    }

    pub async fn execute(executor: &Executor, event: AnyActerEvent) {
        let room_id = event.room_id().to_owned();
        match AnyActerModel::try_from(event) {
            Ok(model) => {
                trace!(?room_id, ?model, "handling timeline event");
                if let Err(e) = executor.handle(model).await {
                    error!("Failure handling event: {:}", e);
                }
            }
            Err(ParseError::ModelRedacted {
                model_type,
                meta,
                reason,
            }) => {
                trace!(?meta.room_id, model_type, ?meta.event_id, "redacted event");
                if let Err(e) = executor.redact(model_type, meta, reason).await {
                    error!("Failure redacting {:}", e);
                }
            }
            Err(ParseError::UnsupportedEvent(AnyActerEvent::RegularTimelineEvent(_))) => {
                // save to hard ignore
                trace!(?room_id, "ignoring timeline event");
            }
            Err(ParseError::UnsupportedEvent(inner)) => {
                // sae to hard ignore
                error!(?room_id, ?inner, "seems like the dev failed to add parsing");
            }
        };
    }
}
