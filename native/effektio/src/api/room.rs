use super::messages::{sync_event_to_message, RoomMessage};
use super::{api, Account, RUNTIME, TimelineStream};
use anyhow::{bail, Context, Result};
use effektio_core::RestoreToken;
use futures::{
    pin_mut, stream, Stream, StreamExt,
    channel::mpsc::{channel, Sender, Receiver},
};
use matrix_sdk::ruma;
use matrix_sdk::{
    attachment::{AttachmentConfig, AttachmentInfo, BaseFileInfo, BaseImageInfo},
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
            AnyMessageLikeEvent, AnyMessageLikeEventContent, AnyRoomEvent,
            AnySyncMessageLikeEvent, AnySyncRoomEvent, MessageLikeEvent, SyncMessageLikeEvent,
        },
        EventId, OwnedUserId, UInt, UserId,
    },
    Client as MatrixClient, RoomType,
};
use parking_lot::Mutex;
use std::{fs::File, io::Write, path::PathBuf, sync::Arc};
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
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let (forward, backward) = room
                    .timeline()
                    .await
                    .context("Failed acquiring timeline streams")?;
                Ok(TimelineStream::new(
                    Box::pin(forward),
                    Box::pin(backward),
                    client,
                    room,
                ))
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
                            if let Some(a) = sync_event_to_message(e, room.clone()) {
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

    pub async fn send_image_message(
        &self,
        uri: String,
        name: String,
        mimetype: String,
        size: u32,
        width: u32,
        height: u32,
    ) -> Result<String> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };
        RUNTIME
            .spawn(async move {
                let path = PathBuf::from(uri);
                let mut image = File::open(path)?;
                let config = AttachmentConfig::new().info(AttachmentInfo::Image(BaseImageInfo {
                    height: Some(UInt::from(height)),
                    width: Some(UInt::from(width)),
                    size: Some(UInt::from(size)),
                    blurhash: None,
                }));
                let mime_type: mime::Mime = mimetype.parse().unwrap();
                let r = room
                    .send_attachment(name.as_str(), &mime_type, &mut image, config)
                    .await?;
                Ok(r.event_id.to_string())
            })
            .await?
    }

    pub fn room_type(&self) -> String {
        match self.room.room_type() {
            RoomType::Joined => "joined".to_owned(),
            RoomType::Left => "left".to_owned(),
            RoomType::Invited => "invited".to_owned(),
        }
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

    pub async fn image_binary(&self, event_id: String) -> Result<api::FfiBuffer<u8>> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };
        let client = self.client.clone();
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                let eid = EventId::parse(event_id.clone())?;
                let evt = room.event(&eid).await?;
                match evt.event.deserialize() {
                    Ok(AnyRoomEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                        MessageLikeEvent::Original(m),
                    ))) => match &m.content.msgtype {
                        MessageType::Image(content) => {
                            let source = content.source.clone();
                            let data = client
                                .get_media_content(
                                    &MediaRequest {
                                        source,
                                        format: MediaFormat::File,
                                    },
                                    false,
                                )
                                .await?;
                            Ok(api::FfiBuffer::new(data))
                        }
                        _ => bail!("Invalid file format"),
                    },
                    _ => bail!("Invalid file format"),
                }
            })
            .await?
    }

    pub async fn invited_from(&self) -> Result<String> {
        let room = if let MatrixRoom::Invited(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't get a room we are not invited")
        };
        RUNTIME
            .spawn(async move {
                let stream = room
                    .timeline_backward()
                    .await
                    .expect("Failed acquiring timeline streams");
                pin_mut!(stream);
                while let Some(item) = stream.next().await {
                    println!("{:?}", item);
                    match item {
                        Ok(ev) => {
                            if let Some(content) = event_content(ev.event.deserialize().unwrap()) {
                                println!("{}", content);
                                return Ok("123 - invited".to_owned());
                                // return Ok(content);
                            }
                        },
                        Err(err) => {
                            println!("Some error occurred!");
                        },
                    }
                    // if let Ok(ev) = item.clone() {
                    //     if let Some(content) = event_content(ev.event.deserialize().unwrap()) {
                    //         println!("{}", content);
                    //         return Ok("123 - invited".to_owned());
                    //         // return Ok(content);
                    //     }
                    // }
                    // if let Err(err) = item {
                    //     println!("Some error occurred!");
                    // }
                }

                bail!("No Message found")
            })
            .await?
    }

    pub async fn send_file_message(
        &self,
        uri: String,
        name: String,
        mimetype: String,
        size: u32,
    ) -> Result<String> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };
        RUNTIME
            .spawn(async move {
                let path = PathBuf::from(uri);
                let mut image = File::open(path)?;
                let config = AttachmentConfig::new().info(AttachmentInfo::File(BaseFileInfo {
                    size: Some(UInt::from(size)),
                }));
                let mime_type: mime::Mime = mimetype.parse().unwrap();
                let r = room
                    .send_attachment(name.as_str(), &mime_type, &mut image, config)
                    .await?;
                Ok(r.event_id.to_string())
            })
            .await?
    }

    pub async fn save_file(&self, event_id: String, dir_path: String) -> Result<bool> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };
        let client = self.client.clone();
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                let eid = EventId::parse(event_id.clone())?;
                let evt = room.event(&eid).await?;
                match evt.event.deserialize() {
                    Ok(AnyRoomEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                        MessageLikeEvent::Original(m),
                    ))) => match m.content.msgtype {
                        MessageType::File(content) => {
                            let source = content.source.clone();
                            let name = content.body.clone();
                            let mut path = PathBuf::from(dir_path.clone());
                            path.push(name);
                            let mut file = File::create(path.clone())?;
                            let data = client
                                .get_media_content(
                                    &MediaRequest {
                                        source,
                                        format: MediaFormat::File,
                                    },
                                    false,
                                )
                                .await?;
                            file.write_all(&data)?;
                            let key =
                                [room.room_id().as_str().as_bytes(), event_id.as_bytes()].concat();
                            client
                                .store()
                                .set_custom_value(&key, path.to_str().unwrap().as_bytes().to_vec())
                                .await?;
                            Ok(true)
                        }
                        _ => Ok(false),
                    },
                    _ => Ok(false),
                }
            })
            .await?
    }

    pub async fn file_path(&self, event_id: String) -> Result<String> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let eid = EventId::parse(event_id.clone())?;
                let evt = room.event(&eid).await?;
                match evt.event.deserialize() {
                    Ok(AnyRoomEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                        MessageLikeEvent::Original(m),
                    ))) => match m.content.msgtype {
                        MessageType::File(content) => {
                            let key = [
                                room.room_id().as_str().as_bytes(),
                                event_id.as_str().as_bytes(),
                            ]
                            .concat();
                            let path = client.store().get_custom_value(&key).await?;
                            match path {
                                Some(value) => {
                                    let text = std::str::from_utf8(&value).unwrap();
                                    Ok(text.to_owned())
                                }
                                None => Ok("".to_owned()),
                            }
                        }
                        _ => Ok("".to_owned()),
                    },
                    _ => Ok("".to_owned()),
                }
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

fn event_content(ev: AnySyncRoomEvent) -> Option<String> {
    if let AnySyncRoomEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(
        SyncMessageLikeEvent::Original(event),
    )) = ev {
        Some(event.content.msgtype.body().to_owned())
    } else {
        None
    }
}

#[cfg(test)]
mod tests {
    use anyhow::Result;
    use matrix_sdk::{
        config::SyncSettings,
        room::Room as MatrixRoom,
        ruma::events::room::message::{OriginalSyncRoomMessageEvent, SyncRoomMessageEvent},
        Client as MatrixClient,
    };
    use ruma::{room_id, OwnedUserId};
    use zenv::{zenv, Zenv};

    use crate::{
        api::{room::Room, Client, ClientStateBuilder},
        platform,
    };

    async fn on_room_message(event: OriginalSyncRoomMessageEvent, room: MatrixRoom) {
        println!("room message");
        if let MatrixRoom::Invited(ref room) = room {
            println!("invited event");
        }
        if let MatrixRoom::Joined(room) = room {
            // let msg_body = match event.content.msgtype {
            //     MessageType::Text(TextMessageEventContent { body, .. }) => body,
            //     _ => return,
            // };

            // if msg_body.contains("!party") {
            //     let content = RoomMessageEventContent::text_plain("🎉🎊🥳 let's PARTY!! 🥳🎊🎉");

            //     println!("sending");

            //     // send our message to the room we found the "!party" command in
            //     // the last parameter is an optional transaction id which we don't
            //     // care about.
            //     room.send(content, None).await.unwrap();

            //     println!("message sent");
            // }
        }
    }
    
    async fn login_and_sync(
        homeserver_url: String,
        base_path: String,
        username: String,
        password: String,
    ) -> Result<Client> {
        let mut client_builder = MatrixClient::builder().homeserver_url(homeserver_url);

        #[cfg(feature = "sled")]
        {
            let state_store = matrix_sdk_sled::StateStore::open_with_path(base_path)?;
            client_builder = client_builder.state_store(state_store);
        }

        let client = client_builder.build().await.unwrap();
        client.login(&username, &password, None, Some("command bot")).await?;
        println!("logged in as {}", username);

        client.sync_once(SyncSettings::default()).await;
        client.register_event_handler(on_room_message).await;

        let settings = SyncSettings::default().token(client.sync_token().await.unwrap());
        client.sync(settings).await;
        println!("456");

        let c = Client::new(
            client,
            ClientStateBuilder::default().is_guest(false).build()?,
        );
        Ok(c)
    }

    #[tokio::test]
    async fn test_invited_from() {
        let z = Zenv::new(".env", false).parse().unwrap();
        let homeserver_url: String = z.get("HOMESERVER_URL").unwrap().to_owned();
        let base_path: String = z.get("BASE_PATH").unwrap().to_owned();
        let username: String = z.get("USERNAME").unwrap().to_owned();
        let password: String = z.get("PASSWORD").unwrap().to_owned();

        let client = login_and_sync(homeserver_url, base_path, username, password)
            .await
            .unwrap();

        let room_id: String = "!jXsqlnitogAbTTSksT:effektio.org".to_owned();
        let room: Room = client.room(room_id).await.expect("Expected room to be available");
        let inviter: String = room.invited_from().await.expect("Expected id of user that invited me");
        println!("inviter: {}", inviter);

        assert_eq!(1, 1);
    }
}
