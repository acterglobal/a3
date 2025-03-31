use matrix_sdk_base::ruma::events::UnsignedRoomRedactionEvent;
use std::sync::PoisonError;

use crate::models::EventMeta;

#[derive(thiserror::Error, Debug)]
pub enum Error {
    #[error("Error in the inner MatrixSDK: {0}")]
    MatrixSdk(#[from] matrix_sdk::Error),

    #[error("Error in the MatrixSDK HTTP: {0}")]
    HttpError(#[from] matrix_sdk::HttpError),

    #[error("Not a known Acter Event")]
    UnknownEvent,

    #[error("Error De/serializing: {0}")]
    Serialization(#[from] serde_json::Error),

    #[error("Error with the matrix sdk Store")]
    Store(#[from] matrix_sdk::StoreError),

    #[error("IO Error: {0}")]
    IoError(#[from] std::io::Error),

    #[error("Store Dirty Lock Poisoned Error.")]
    StoreDirtyPoisoned,

    #[error("Model not found at {0}.")]
    ModelNotFound(String),

    #[error("Index not found.")]
    IndexNotFound,

    #[error("Your Homeserver doesn’t have a hostname, that is required for this action.")]
    HomeserverMissesHostname,

    #[error("The client must be logged in for this interaction.")]
    ClientNotLoggedIn,

    #[error("Model {0:?} unknown")]
    UnknownModel(Option<String>),

    #[error("Failed to parse {model_type}: {msg}")]
    FailedToParse { model_type: String, msg: String },

    #[error("Id Parse Error: {0}")]
    IdParseError(#[from] matrix_sdk_base::ruma::IdParseError),

    #[error("Model {meta:?} ({model_type}): {reason:?}")]
    ModelRedacted {
        model_type: String,
        meta: EventMeta,
        reason: UnsignedRoomRedactionEvent,
    },

    #[error("{0:?} field is missing")]
    MissingField(String),

    #[error("{0}")]
    Custom(String),
}

impl<T> From<PoisonError<T>> for Error {
    fn from(_err: PoisonError<T>) -> Self {
        Self::StoreDirtyPoisoned
    }
}

pub type Result<T> = std::result::Result<T, Error>;
