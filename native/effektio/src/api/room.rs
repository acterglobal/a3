use super::messages::{sync_event_to_message, RoomMessage};
use super::{api, TimelineStream, RUNTIME};
use anyhow::{bail, Context, Result};
use effektio_core::RestoreToken;
use futures::{pin_mut, stream, Stream, StreamExt};
use matrix_sdk::ruma;
use matrix_sdk::{
    media::{MediaFormat, MediaRequest},
    room::Room as MatrixRoom,
    ruma::{
        events::{
            room::{
                member::StrippedRoomMemberEvent,
                message::{
                    MessageType, OriginalSyncRoomMessageEvent,
                    RoomMessageEventContent, TextMessageEventContent,
                },
            },
            AnyMessageLikeEventContent,
        },
        EventId, OwnedUserId, UserId,
    },
    Client as MatrixClient,
};
use tokio::time::{sleep, Duration};

pub struct Member {
    pub(crate) member: matrix_sdk::RoomMember,
}

impl std::ops::Deref for Member {
    type Target = matrix_sdk::RoomMember;
    fn deref(&self) -> &matrix_sdk::RoomMember {
        &self.member
    }
}

impl Member {
    pub async fn avatar(&self) -> Result<api::FfiBuffer<u8>> {
        let r = self.member.clone();
        RUNTIME
            .spawn(async move {
                Ok(api::FfiBuffer::new(
                    r.avatar(MediaFormat::File).await?.context("No avatar")?,
                ))
            })
            .await?
    }
    pub fn display_name(&self) -> Option<String> {
        self.member.display_name().map(|s| s.to_owned())
    }

    pub fn user_id(&self) -> OwnedUserId {
        self.member.user_id().to_owned()
    }
}

pub struct Room {
    pub(crate) client: MatrixClient,
    pub(crate) room: MatrixRoom,
}

impl Room {
    pub async fn display_name(&self) -> Result<String> {
        let r = self.room.clone();
        RUNTIME
            .spawn(async move { Ok(r.display_name().await?.to_string()) })
            .await?
    }

    pub async fn avatar(&self) -> Result<api::FfiBuffer<u8>> {
        let r = self.room.clone();
        RUNTIME
            .spawn(async move {
                Ok(api::FfiBuffer::new(
                    r.avatar(MediaFormat::File).await?.context("No avatar")?,
                ))
            })
            .await?
    }

    pub async fn active_members(&self) -> Result<Vec<Member>> {
        let r = self.room.clone();
        RUNTIME
            .spawn(async move {
                Ok(r.active_members()
                    .await
                    .context("No members")?
                    .into_iter()
                    .map(|member| Member { member })
                    .collect())
            })
            .await?
    }

    pub async fn active_members_no_sync(&self) -> Result<Vec<Member>> {
        let r = self.room.clone();
        RUNTIME
            .spawn(async move {
                Ok(r.active_members_no_sync()
                    .await
                    .context("No members")?
                    .into_iter()
                    .map(|member| Member { member })
                    .collect())
            })
            .await?
    }

    pub async fn get_member(&self, user_id: Box<OwnedUserId>) -> Result<Member> {
        let r = self.room.clone();
        RUNTIME
            .spawn(async move {
                let member = r.get_member(&user_id).await?.context("User not found")?;
                Ok(Member { member })
            })
            .await?
    }

    pub async fn timeline(&self) -> Result<TimelineStream> {
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let (forward, backward) = room
                    .timeline()
                    .await
                    .context("Failed acquiring timeline streams")?;
                Ok(TimelineStream::new(Box::pin(forward), Box::pin(backward)))
            })
            .await?
    }

    pub async fn latest_message(&self) -> Result<RoomMessage> {
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let stream = room
                    .timeline_backward()
                    .await
                    .context("Failed acquiring timeline streams")?;
                pin_mut!(stream);
                loop {
                    match stream.next().await {
                        None => break,
                        Some(Ok(e)) => {
                            if let Some(a) = sync_event_to_message(e) {
                                return Ok(a);
                            }
                        }
                        _ => {
                            // we ignore errors
                        }
                    }
                }

                bail!("No Message found")
            })
            .await?
    }
    pub async fn typing_notice(&self, typing: bool) -> Result<bool> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send typing notice to a room we are not in")
        };
        RUNTIME
            .spawn(async move {
                room.typing_notice(typing).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn read_receipt(&self, event_id: String) -> Result<bool> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send read_receipt to a room we are not in")
        };
        let event_id = EventId::parse(event_id)?;
        RUNTIME
            .spawn(async move {
                room.read_receipt(&event_id).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn send_plain_message(&self, message: String) -> Result<String> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };
        RUNTIME
            .spawn(async move {
                let r = room
                    .send(
                        AnyMessageLikeEventContent::RoomMessage(
                            RoomMessageEventContent::text_plain(message),
                        ),
                        None,
                    )
                    .await?;
                Ok(r.event_id.to_string())
            })
            .await?
    }

    pub async fn invite_user(&self, user_id: String) -> Result<bool> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                let user = <&UserId>::try_from(user_id.as_str()).unwrap();
                room.invite_user_by_id(user).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn accept_invitation(&self) -> Result<bool> {
        let room = if let MatrixRoom::Invited(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't join a room we are not invited")
        };
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                let mut delay = 2;
                while let Err(err) = room.accept_invitation().await {
                    // retry autojoin due to synapse sending invites, before the
                    // invited user can join for more information see
                    // https://github.com/matrix-org/synapse/issues/4345
                    eprintln!("Failed to join room {} ({:?}), retrying in {}s", room.room_id(), err, delay);

                    sleep(Duration::from_secs(delay)).await;
                    delay *= 2;

                    if delay > 3600 {
                        eprintln!("Can't join room {} ({:?})", room.room_id(), err);
                        break;
                    }
                }
                println!("Successfully joined room {}", room.room_id());
                Ok(delay <= 3600)
            })
            .await?
    }
}

impl std::ops::Deref for Room {
    type Target = MatrixRoom;
    fn deref(&self) -> &MatrixRoom {
        &self.room
    }
}
