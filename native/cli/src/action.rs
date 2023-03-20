use anyhow::Result;

mod execute;
mod history;
mod list;
mod manage;
mod mock;

pub use execute::ExecuteOpts;
pub use history::HistoryOpts;
pub use list::List;
pub use manage::Manage;
pub use mock::MockOpts;

#[derive(clap::Subcommand, Debug)]
pub enum Action {
    /// List rooms
    List(List),
    /// Room Management
    Manage(Manage),
    /// Reviewing the room history
    History(HistoryOpts),
    /// Mock Data on fresh server
    Mock(MockOpts),
    /// Template Execution
    Execute(ExecuteOpts),
}

impl Action {
    pub async fn run(&self) -> Result<()> {
        match self {
            Action::Manage(config) => config.run().await?,
            Action::Mock(config) => config.run().await?,
            Action::List(config) => config.run().await?,
            Action::History(config) => config.run().await?,
            Action::Execute(config) => config.run().await?,
        };
        Ok(())
    }
}
