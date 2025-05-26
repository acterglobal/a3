use acter_core::events::{
    rsvp::RsvpStatus, ColorizeBuilder, DisplayBuilder, ObjRefBuilder, Position,
};
use anyhow::{Context, Result};
use core::time::Duration;
use matrix_sdk::{HttpError, RumaApiError};
use matrix_sdk_base::{
    media::{MediaFormat, MediaThumbnailSettings},
    ruma::{
        api::{client::error::ErrorBody, error::FromHttpResponseError},
        events::room::{
            message::UrlPreview as RumaUrlPreview, MediaSource as SdkMediaSource,
            ThumbnailInfo as SdkThumbnailInfo,
        },
        MilliSecondsSinceUnixEpoch, OwnedDeviceId, OwnedEventId, OwnedUserId, UInt,
    },
    ComposerDraft, ComposerDraftType,
};
use serde::{Deserialize, Serialize};
use std::{ops::Deref, str::FromStr};
use tracing::error;

use super::api::FfiBuffer;
use super::RefDetails;

pub fn duration_from_secs(secs: u64) -> Duration {
    Duration::from_secs(secs)
}

pub struct OptionString {
    text: Option<String>,
}

impl OptionString {
    pub(crate) fn new(text: Option<String>) -> Self {
        OptionString { text }
    }

    pub fn text(&self) -> Option<String> {
        self.text.clone()
    }
}

impl From<Option<String>> for OptionString {
    fn from(text: Option<String>) -> Self {
        OptionString { text }
    }
}

pub struct OptionBuffer {
    pub(crate) data: Option<Vec<u8>>,
}

impl OptionBuffer {
    pub(crate) fn new(data: Option<Vec<u8>>) -> Self {
        OptionBuffer { data }
    }

    pub fn data(&self) -> Option<FfiBuffer<u8>> {
        self.data.clone().map(FfiBuffer::new)
    }
}

pub struct OptionRsvpStatus {
    pub(crate) status: Option<RsvpStatus>,
}

impl OptionRsvpStatus {
    pub(crate) fn new(status: Option<RsvpStatus>) -> Self {
        OptionRsvpStatus { status }
    }

    pub fn status(&self) -> Option<RsvpStatus> {
        self.status.clone()
    }

    pub fn status_str(&self) -> Option<String> {
        self.status.as_ref().map(ToString::to_string)
    }
}
#[derive(Clone)]
pub struct OptionComposeDraft {
    draft: Option<ComposeDraft>,
}

impl OptionComposeDraft {
    pub(crate) fn new(draft: Option<ComposeDraft>) -> Self {
        OptionComposeDraft { draft }
    }

    pub fn draft(&self) -> Option<ComposeDraft> {
        self.draft.clone()
    }
}

pub struct MediaSource {
    pub(crate) inner: SdkMediaSource,
}

impl From<&SdkMediaSource> for MediaSource {
    fn from(value: &SdkMediaSource) -> Self {
        MediaSource {
            inner: value.clone(),
        }
    }
}

impl MediaSource {
    pub fn url(&self) -> String {
        match self.inner.clone() {
            SdkMediaSource::Plain(url) => url.to_string(),
            SdkMediaSource::Encrypted(file) => file.url.to_string(),
        }
    }
}

#[derive(Clone)]
pub struct ThumbnailInfo {
    pub(crate) inner: SdkThumbnailInfo,
}

impl From<&SdkThumbnailInfo> for ThumbnailInfo {
    fn from(value: &SdkThumbnailInfo) -> Self {
        ThumbnailInfo {
            inner: value.clone(),
        }
    }
}

impl ThumbnailInfo {
    pub fn mimetype(&self) -> Option<String> {
        self.inner.mimetype.clone()
    }

    pub fn size(&self) -> Option<u64> {
        self.inner.size.map(Into::into)
    }

    pub fn width(&self) -> Option<u64> {
        self.inner.width.map(Into::into)
    }

    pub fn height(&self) -> Option<u64> {
        self.inner.height.map(Into::into)
    }
}

pub struct UrlPreview(pub(crate) RumaUrlPreview);

impl UrlPreview {
    pub fn from(prev: &RumaUrlPreview) -> Self {
        Self(prev.clone())
    }
    pub fn new(prev: RumaUrlPreview) -> Self {
        Self(prev)
    }
    pub fn url(&self) -> Option<String> {
        self.0.url.clone()
    }
    pub fn title(&self) -> Option<String> {
        self.0.title.clone()
    }
    pub fn description(&self) -> Option<String> {
        self.0.description.clone()
    }

    pub fn has_image(&self) -> bool {
        false // not yet supported
              // !self.0.image.is_none()
    }
    pub fn image_source(&self) -> Option<MediaSource> {
        None // not yet support
             // self.0.image.as_ref().map(|image| MediaSource {
             //     inner: match image.source {
             //         PreviewImageSource::EncryptedImage(e) => SdkMediaSource::Encrypted(e.clone()),
             //         PreviewImageSource::Url(u) => SdkMediaSource::Plain(u.clone()),
             //     },
             // })
    }
}

#[derive(Clone)]
pub struct ComposeDraft {
    inner: ComposerDraft,
}

impl ComposeDraft {
    pub fn new(
        plain_text: String,
        html_text: Option<String>,
        msg_type: String,
        event_id: Option<OwnedEventId>,
    ) -> Self {
        let m_type = msg_type.clone();
        let draft_type = match (m_type.as_str(), event_id) {
            ("new", None) => ComposerDraftType::NewMessage,
            ("edit", Some(id)) => ComposerDraftType::Edit { event_id: id },
            ("reply", Some(id)) => ComposerDraftType::Reply { event_id: id },
            _ => ComposerDraftType::NewMessage,
        };

        ComposeDraft {
            inner: ComposerDraft {
                plain_text,
                html_text,
                draft_type,
            },
        }
    }

    pub fn inner(&self) -> ComposerDraft {
        self.inner.clone()
    }

    pub fn plain_text(&self) -> String {
        self.inner.plain_text.clone()
    }

    pub fn html_text(&self) -> Option<String> {
        self.inner.html_text.clone()
    }

    // only valid for reply and edit drafts
    pub fn event_id(&self) -> Option<String> {
        match &(self.inner.draft_type) {
            ComposerDraftType::Edit { event_id } => Some(event_id.to_string()),
            ComposerDraftType::Reply { event_id } => Some(event_id.to_string()),
            ComposerDraftType::NewMessage => None,
        }
    }

    pub fn draft_type(&self) -> String {
        match &(self.inner.draft_type) {
            ComposerDraftType::NewMessage => "new".to_owned(),
            ComposerDraftType::Edit { event_id } => "edit".to_owned(),
            ComposerDraftType::Reply { event_id } => "reply".to_owned(),
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ReactionRecord {
    sender_id: OwnedUserId,
    timestamp: MilliSecondsSinceUnixEpoch,
    sent_by_me: bool,
}

impl ReactionRecord {
    pub(crate) fn new(
        sender_id: OwnedUserId,
        timestamp: MilliSecondsSinceUnixEpoch,
        sent_by_me: bool,
    ) -> Self {
        ReactionRecord {
            sender_id,
            timestamp,
            sent_by_me,
        }
    }

    pub fn sender_id(&self) -> OwnedUserId {
        self.sender_id.clone()
    }

    pub fn sent_by_me(&self) -> bool {
        self.sent_by_me
    }

    pub fn timestamp(&self) -> u64 {
        self.timestamp.get().into()
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct DeviceRecord {
    device_id: OwnedDeviceId,
    display_name: Option<String>,
    last_seen_ts: Option<MilliSecondsSinceUnixEpoch>,
    last_seen_ip: Option<String>,
    is_verified: bool,
    is_active: bool,
    is_me: bool,
}

impl DeviceRecord {
    pub(crate) fn new(
        device_id: OwnedDeviceId,
        display_name: Option<String>,
        last_seen_ts: Option<MilliSecondsSinceUnixEpoch>,
        last_seen_ip: Option<String>,
        is_verified: bool,
        is_active: bool,
        is_me: bool,
    ) -> Self {
        DeviceRecord {
            device_id,
            display_name,
            last_seen_ts,
            last_seen_ip,
            is_verified,
            is_active,
            is_me,
        }
    }

    pub fn device_id(&self) -> OwnedDeviceId {
        self.device_id.clone()
    }

    pub fn display_name(&self) -> Option<String> {
        self.display_name.clone()
    }

    pub fn last_seen_ts(&self) -> Option<u64> {
        self.last_seen_ts.map(|x| x.get().into())
    }

    pub fn last_seen_ip(&self) -> Option<String> {
        self.last_seen_ip.clone()
    }

    pub fn is_verified(&self) -> bool {
        self.is_verified
    }

    pub fn is_me(&self) -> bool {
        self.is_me
    }

    pub fn is_active(&self) -> bool {
        self.is_active
    }
}

#[derive(Clone, Debug)]
pub struct ThumbnailSize {
    width: UInt,
    height: UInt,
}

impl ThumbnailSize {
    pub(crate) fn new(width: u64, height: u64) -> Result<Self> {
        let width = UInt::new(width).context("invalid thumbnail width")?;
        let height = UInt::new(height).context("invalid thumbnail height")?;
        Ok(ThumbnailSize { width, height })
    }

    pub(crate) fn width(&self) -> UInt {
        self.width
    }

    pub(crate) fn height(&self) -> UInt {
        self.height
    }

    pub fn parse_into_media_format(thumb_size: Option<Box<ThumbnailSize>>) -> MediaFormat {
        match thumb_size {
            Some(thumb_size) => MediaFormat::from(thumb_size),
            None => MediaFormat::File,
        }
    }
}

impl From<Box<ThumbnailSize>> for MediaFormat {
    fn from(val: Box<ThumbnailSize>) -> Self {
        MediaFormat::Thumbnail(MediaThumbnailSettings::new(val.width, val.height))
    }
}

pub fn new_thumb_size(width: u64, height: u64) -> Result<ThumbnailSize> {
    ThumbnailSize::new(width, height)
}

pub fn new_colorize_builder(
    color: Option<u32>,
    background: Option<u32>,
    link: Option<u32>,
) -> Result<ColorizeBuilder> {
    let mut builder = ColorizeBuilder::default();
    if let Some(color) = color {
        builder.color(color);
    }
    if let Some(background) = background {
        builder.background(background);
    }
    if let Some(link) = link {
        builder.link(link);
    }
    Ok(builder)
}

pub fn new_obj_ref_builder(
    position: Option<String>,
    reference: Box<RefDetails>,
) -> Result<ObjRefBuilder> {
    if let Some(p) = position {
        let p = Position::from_str(&p)?;
        Ok(ObjRefBuilder::new(Some(p), (*reference).deref().clone()))
    } else {
        Ok(ObjRefBuilder::new(None, (*reference).deref().clone()))
    }
}

pub fn clearify_error(err: matrix_sdk::Error) -> anyhow::Error {
    if let matrix_sdk::Error::Http(boxed) = &err {
        match boxed.as_ref() {
            HttpError::Api(a) => 
            match a.deref() {
                FromHttpResponseError::Deserialization(des) => {
                    return anyhow::anyhow!("Deserialization failed: {des}");
                }
                FromHttpResponseError::Server(RumaApiError::ClientApi(error)) => {
                    if let ErrorBody::Standard { kind, message } = &error.body {
                        return anyhow::anyhow!("{message:?} [{kind:?}]");
                    }
                    return anyhow::anyhow!("{0:?} [{1}]", error.body, error.status_code);
                }
                FromHttpResponseError::Server(RumaApiError::Uiaa(uiaa_error)) => {
                    if let Some(err) = &uiaa_error.auth_error {
                        return anyhow::anyhow!("{:?} [{:?}]", err.message, err.kind);
                    }
                    error!(?uiaa_error, "Other UIAA response");
                    return anyhow::anyhow!("Unsupported User Interaction needed.");
                }
                FromHttpResponseError::Server(RumaApiError::Other(err)) => {
                    return anyhow::anyhow!("{:?} [{:?}]", err.body, err.status_code);
                }
                _ => {}
            },
            HttpError::Reqwest(reqwest_error) => {
                return anyhow::anyhow!("Transport error {:?}", reqwest_error);
            }
            _ => {}
        }
    }
    err.into()
}

pub fn new_display_builder() -> DisplayBuilder {
    DisplayBuilder::default()
}
