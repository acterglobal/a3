use matrix_sdk::Error as MatrixError;

#[derive(thiserror::Error, Debug)]
pub enum Error {
    #[error("Error in the inner MatrixSDK")]
    MatrixSdk(#[from] MatrixError),

    #[error("Not a known Effektio Event")]
    UnknownEvent,

    #[error("Error De/serializing: {0}")]
    Serialization(#[from] serde_json::Error),

    #[error("Error with the matrix sdk Store")]
    Store(#[from] matrix_sdk::StoreError),

    #[error("Reference Model not found.")]
    ModelNotFound,

    #[error("Index not found.")]
    IndexNotFound,

    #[error("{0}")]
    Custom(String),
}

pub type Result<T> = std::result::Result<T, Error>;
