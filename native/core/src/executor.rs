use matrix_sdk::{deserialized_responses::RoomEvent, Client as MatrixClient, Error as MatrixError};

#[derive(thiserror::Error, Debug)]
pub enum ExecutorError {
    #[error("Error in the inner MatrixSDK")]
    MatrixSdk(#[from] MatrixError),
}

pub type Result<T> = std::result::Result<T, ExecutorError>;

#[derive(Clone, Debug)]
pub struct Executor {
    client: MatrixClient,
}

impl Executor {
    pub async fn new(client: MatrixClient) -> Result<Self> {
        Ok(Executor { client })
    }
    pub async fn handle(&self, _msg: RoomEvent) -> Result<()> {
        Ok(())
    }
}
