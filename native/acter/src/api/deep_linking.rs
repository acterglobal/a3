use std::ops::Deref;
use std::sync::Arc;

use crate::{Client, RUNTIME};
use acter_core::events::{ObjRef as CoreObjRef, RefDetails as CoreRefDetails};
use acter_core::share_link::api;
use anyhow::{bail, Result};
use matrix_sdk::Client as SdkClient;
use ruma::{OwnedEventId, OwnedRoomId, OwnedServerName};
use urlencoding::encode;

#[derive(Clone)]
pub struct ObjRef {
    client: SdkClient,
    inner: CoreObjRef,
}

impl Deref for ObjRef {
    type Target = CoreObjRef;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl ObjRef {
    pub(crate) fn new(client: SdkClient, inner: CoreObjRef) -> Self {
        Self { client, inner }
    }

    pub fn ref_details(&self) -> RefDetails {
        RefDetails {
            inner: self.inner.ref_details(),
            client: self.client.clone(),
        }
    }
}
pub struct RefDetails {
    inner: CoreRefDetails,
    client: SdkClient,
}

impl Deref for RefDetails {
    type Target = CoreRefDetails;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

pub fn new_link_ref_details(title: String, uri: String) -> Result<CoreRefDetails> {
    Ok(CoreRefDetails::Link { title, uri })
}

impl Client {
    /// create a link ref details
    pub fn new_link_ref_details(&self, title: String, uri: String) -> Result<RefDetails> {
        Ok(RefDetails::new(
            self.core.client().clone(),
            new_link_ref_details(title, uri)?,
        ))
    }
}

fn generate_object_link(
    room_id: &OwnedRoomId,
    path: &[(&str, &OwnedEventId)],
    via: &[OwnedServerName],
    params: &[(&str, Option<&String>)],
) -> String {
    let room_id = &room_id.to_string()[1..];
    format!(
        "acter:o/{room_id}/{}?{}",
        path.iter()
            .map(|(p, o)| format!("{p}/{}", &o.to_string()[1..]))
            .collect::<Vec<String>>()
            .join("/"),
        via.iter()
            .map(|v| format!("via={}", encode(v.as_str())))
            .chain(
                params
                    .iter()
                    .filter_map(|(key, v)| v.map(|i| format!("{key}={}", encode(i.as_str()))))
            )
            .collect::<Vec<String>>()
            .join("&")
    )
}

impl RefDetails {
    pub(crate) fn new(client: SdkClient, inner: CoreRefDetails) -> Self {
        Self { client, inner }
    }

    pub fn can_generate_internal_link(&self) -> bool {
        match &self.inner {
            CoreRefDetails::Link { title, uri } => false,
            CoreRefDetails::Task { room_id, .. }
            | CoreRefDetails::TaskList { room_id, .. }
            | CoreRefDetails::News { room_id, .. }
            | CoreRefDetails::Pin { room_id, .. }
            | CoreRefDetails::CalendarEvent { room_id, .. } => room_id.is_some(),
        }
    }

    pub fn generate_internal_link(&self, include_preview: bool) -> Result<String> {
        Ok(match &self.inner {
            CoreRefDetails::Link { title, uri } => bail!("Link can't be made into internal link"),
            CoreRefDetails::Task {
                target_id,
                room_id,
                via,
                preview,
                task_list,
                action,
            } => {
                let Some(room_id) = room_id else {
                    bail!("Object misses room_id")
                };
                let params = if include_preview {
                    vec![
                        ("roomDisplayName", preview.room_display_name.as_ref()),
                        ("title", preview.title.as_ref()),
                    ]
                } else {
                    vec![]
                };

                generate_object_link(
                    room_id,
                    &[("taskList", task_list), ("task", target_id)],
                    via.as_slice(),
                    params.as_slice(),
                )
            }
            CoreRefDetails::TaskList {
                target_id,
                room_id,
                via,
                preview,
                action,
            } => {
                let Some(room_id) = room_id else {
                    bail!("Object misses room_id")
                };
                let params = if include_preview {
                    vec![
                        ("roomDisplayName", preview.room_display_name.as_ref()),
                        ("title", preview.title.as_ref()),
                    ]
                } else {
                    vec![]
                };

                generate_object_link(
                    room_id,
                    &[("taskList", target_id)],
                    via.as_slice(),
                    params.as_slice(),
                )
            }
            CoreRefDetails::Pin {
                target_id,
                room_id,
                via,
                preview,
                action,
            } => {
                let Some(room_id) = room_id else {
                    bail!("Object misses room_id")
                };
                let params = if include_preview {
                    vec![
                        ("roomDisplayName", preview.room_display_name.as_ref()),
                        ("title", preview.title.as_ref()),
                    ]
                } else {
                    vec![]
                };

                generate_object_link(
                    room_id,
                    &[("pin", target_id)],
                    via.as_slice(),
                    params.as_slice(),
                )
            }
            CoreRefDetails::News {
                target_id,
                room_id,
                via,
                preview,
            } => {
                let Some(room_id) = room_id else {
                    bail!("Object misses room_id")
                };
                let params = if include_preview {
                    vec![
                        ("roomDisplayName", preview.room_display_name.as_ref()),
                        ("title", preview.title.as_ref()),
                    ]
                } else {
                    vec![]
                };

                generate_object_link(
                    room_id,
                    &[("boost", target_id)],
                    via.as_slice(),
                    params.as_slice(),
                )
            }
            CoreRefDetails::CalendarEvent {
                target_id,
                room_id,
                via,
                preview,
                action,
            } => {
                let Some(room_id) = room_id else {
                    bail!("Object misses room_id")
                };
                let participants = preview.participants.as_ref().map(ToString::to_string);
                let start_at = preview
                    .start_at_utc
                    .as_ref()
                    .map(|s| s.timestamp().to_string());
                let params = if include_preview {
                    vec![
                        ("roomDisplayName", preview.room_display_name.as_ref()),
                        ("title", preview.title.as_ref()),
                        ("participants", participants.as_ref()),
                        ("startAtUtc", start_at.as_ref()),
                    ]
                } else {
                    vec![]
                };

                generate_object_link(
                    room_id,
                    &[("calendarEvent", target_id)],
                    via.as_slice(),
                    params.as_slice(),
                )
            }
        })
    }

    pub async fn generate_external_link(&self) -> Result<String> {
        let c = self.client.clone();
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                let req = api::create::Request::new(inner);
                let resp = c.send(req, None).await?;
                Ok(resp.url)
            })
            .await?
    }
}
