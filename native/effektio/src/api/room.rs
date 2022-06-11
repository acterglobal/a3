use super::messages::{sync_event_to_message, RoomMessage};
use super::{api, Account, TimelineStream, RUNTIME};
use anyhow::{bail, Context, Result};
use effektio_core::RestoreToken;
use futures::{
    pin_mut, stream, Stream, StreamExt,
    channel::mpsc::{channel, Sender, Receiver},
};
use matrix_sdk::ruma;
use matrix_sdk::{
    media::{MediaFormat, MediaRequest},
    room::Room as MatrixRoom,
    ruma::{
        events::{
            room::{
                member::{RoomMemberEvent, StrippedRoomMemberEvent},
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
use parking_lot::Mutex;
use std::sync::Arc;
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

    pub fn listen_to_member_events(&self) -> Result<Receiver<String>> {
        let room_id = self.room.room_id().to_owned().clone();
        let client = self.client.clone();
        let (tx, rx) = channel::<String>(10); // dropping after more than 10 items queued
        let sender_arc = Arc::new(Mutex::new(tx));
        RUNTIME.block_on(async move {
            client
                .register_event_handler(move |ev: StrippedRoomMemberEvent, c: MatrixClient, room: MatrixRoom| {
                    let sender_arc = sender_arc.clone();
                    let room_id = room_id.clone();
                    async move {
                        let s = sender_arc.lock();
                        if room.room_id() == room_id {
                            if let Err(e) = s.clone().try_send(ev.sender.to_string()) {
                                log::warn!("Dropping member event for {}: {}", room_id, e);
                            }
                        }
                        // the lock is unlocked here when `s` goes out of scope.
                    }
                })
                .await;
        });
        Ok(rx)
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

    pub fn is_joined(&self) -> bool {
        if let MatrixRoom::Joined(r) = &self.room {
            return true;
        } else {
            return false;
        };
    }

    pub fn is_invited(&self) -> bool {
        if let MatrixRoom::Invited(r) = &self.room {
            return true;
        } else {
            return false;
        };
    }

    pub fn is_left(&self) -> bool {
        if let MatrixRoom::Left(r) = &self.room {
            return true;
        } else {
            return false;
        };
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
                    eprintln!("Failed to accept room {} ({:?}), retrying in {}s", room.room_id(), err, delay);

                    sleep(Duration::from_secs(delay)).await;
                    delay *= 2;

                    if delay > 3600 {
                        eprintln!("Can't accept room {} ({:?})", room.room_id(), err);
                        break;
                    }
                }
                println!("Successfully accepted room {}", room.room_id());
                Ok(delay <= 3600)
            })
            .await?
    }

    pub async fn reject_invitation(&self) -> Result<bool> {
        let room = if let MatrixRoom::Invited(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't join a room we are not invited")
        };
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                let mut delay = 2;
                while let Err(err) = room.reject_invitation().await {
                    // retry autojoin due to synapse sending invites, before the
                    // invited user can join for more information see
                    // https://github.com/matrix-org/synapse/issues/4345
                    eprintln!("Failed to reject room {} ({:?}), retrying in {}s", room.room_id(), err, delay);

                    sleep(Duration::from_secs(delay)).await;
                    delay *= 2;

                    if delay > 3600 {
                        eprintln!("Can't reject room {} ({:?})", room.room_id(), err);
                        break;
                    }
                }
                println!("Successfully rejected room {}", room.room_id());
                Ok(delay <= 3600)
            })
            .await?
    }

    pub async fn join(&self) -> Result<bool> {
        let room = if let MatrixRoom::Left(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't join a room we are not left")
        };
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                room.join().await?;
                Ok(true)
            })
            .await?
    }

    pub async fn leave(&self) -> Result<bool> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't leave a room we are not joined")
        };
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                room.leave().await?;
                Ok(true)
            })
            .await?
    }

    pub async fn get_invited_users(&self) -> Result<Vec<Account>> {
        let my_client = self.client.clone();
        let room = if let MatrixRoom::Invited(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't get a room we are not invited")
        };
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                let invited = my_client
                    .store()
                    .get_invited_user_ids(room.room_id())
                    .await
                    .unwrap();
                let mut accounts: Vec<Account> = vec![];
                for user_id in invited.iter() {
                    let other_client = MatrixClient::builder().user_id(&user_id).build().await.unwrap();
                    accounts.push(Account::new(other_client.account(), user_id.as_str().to_owned()));
                }
                Ok(accounts)
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
