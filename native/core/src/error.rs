use matrix_sdk::{Error as MatrixError, HttpError};

#[derive(thiserror::Error, Debug)]
pub enum Error {
    #[error("Error in the inner MatrixSDK")]
    MatrixSdk(#[from] MatrixError),

    #[error("Error in the MatrixSDK HTTP")]
    HttpError(#[from] HttpError),

    #[error("Not a known Acter Event")]
    UnknownEvent,

    #[error("Error De/serializing: {0}")]
    Serialization(#[from] serde_json::Error),

    #[error("Error with the matrix sdk Store")]
    Store(#[from] matrix_sdk::StoreError),

    #[error("Reference Model not found.")]
    ModelNotFound,

    #[error("Index not found.")]
    IndexNotFound,

    #[error("Model {0:?} unknown")]
    UnknownModel(Option<String>),

    #[error("Failed to parse {model_type}: {msg}")]
    FailedToParse { model_type: String, msg: String },

    #[error("{0}")]
    Custom(String),
}

pub type Result<T> = std::result::Result<T, Error>;
