use core::result::Result as CoreResult;

#[derive(Debug, uniffi::Error, thiserror::Error)]
#[uniffi(flat_error)]
pub enum ActerError {
    #[error("data store disconnected")]
    Disconnect(#[from] std::io::Error),
    #[error("unknown processing error")]
    Unknown,
    #[error("{0}")]
    Anyhow(#[from] anyhow::Error),
}

pub type Result<T> = CoreResult<T, ActerError>;
