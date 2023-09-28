use anyhow::{bail, Result};
use eyeball_im::VectorDiff;
use futures::stream::{Stream, StreamExt};
use matrix_sdk::{room::Room, RoomState};
use matrix_sdk_ui::timeline::{BackPaginationStatus, PaginationOptions, Timeline};
use ruma_common::EventId;
use ruma_events::{
    relation::Replacement,
    room::message::{MessageType, Relation, RoomMessageEvent, RoomMessageEventContent},
};
use std::sync::Arc;
use tracing::{error, info};

use super::{
    message::RoomMessage,
    utils::{remap_for_diff, ApiVectorDiff},
    RUNTIME,
};

pub type TimelineDiff = ApiVectorDiff<RoomMessage>;

#[derive(Clone)]
pub struct TimelineStream {
    room: Room,
    timeline: Arc<Timeline>,
}

impl TimelineStream {
    pub fn new(room: Room, timeline: Arc<Timeline>) -> Self {
        TimelineStream { room, timeline }
    }

    pub fn diff_stream(&self) -> impl Stream<Item = TimelineDiff> {
        let timeline = self.timeline.clone();
        let room = self.room.clone();

        async_stream::stream! {
            let (timeline_items, mut timeline_stream) = timeline.subscribe().await;
            yield TimelineDiff::current_items(timeline_items.clone().into_iter().map(|x| RoomMessage::from((x, room.clone()))).collect());

            let mut remap = timeline_stream.map(|diff| remap_for_diff(
                diff,
                |x| RoomMessage::from((x, room.clone())),
            ));

            while let Some(d) = remap.next().await {
                yield d
            }
        }
    }

    pub async fn paginate_backwards(&self, mut count: u16) -> Result<bool> {
        let timeline = self.timeline.clone();

        RUNTIME
            .spawn(async move {
                let mut back_pagination_status = timeline.back_pagination_status();
                let (timeline_items, mut timeline_stream) = timeline.subscribe().await;
                timeline
                    .paginate_backwards(PaginationOptions::single_request(count))
                    .await?;
                loop {
                    if let Some(status) = back_pagination_status.next().await {
                        if status == BackPaginationStatus::Idle {
                            return Ok(true); // has more
                        }
                        if status == BackPaginationStatus::TimelineStartReached {
                            return Ok(false); // no more
                        }
                    }
                }
            })
            .await?
    }

    fn is_joined(&self) -> bool {
        matches!(self.room.state(), RoomState::Joined)
    }

    pub async fn edit(&self, new_msg: String, original_event_id: String) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't edit message from a room we are not in");
        }
        let room = self.room.clone();
        let timeline = self.timeline.clone();
        let event_id = EventId::parse(original_event_id)?;
        let client = self.room.client();

        RUNTIME
            .spawn(async move {
                let timeline_event = room.event(&event_id).await?;
                let event_content = timeline_event.event.deserialize_as::<RoomMessageEvent>()?;

                let mut sent_by_me = false;
                if let Some(user_id) = client.user_id() {
                    if user_id == event_content.sender() {
                        sent_by_me = true;
                    }
                }
                if !sent_by_me {
                    error!("Can't edit an event not sent by own user");
                    return Ok(false);
                }

                let replacement = Replacement::new(
                    event_id.to_owned(),
                    MessageType::text_markdown(new_msg.to_string()).into(),
                );
                let mut edited_content = RoomMessageEventContent::text_markdown(new_msg);
                edited_content.relates_to = Some(Relation::Replacement(replacement));

                timeline.send(edited_content.into()).await;
                Ok(true)
            })
            .await?
    }
}
