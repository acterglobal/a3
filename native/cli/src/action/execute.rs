use anyhow::{bail, Result};
use clap::Parser;
use futures::{pin_mut, stream::StreamExt};
use std::{collections::HashMap, fs, path::PathBuf};
use tracing::info;

use crate::config::LoginConfig;

#[derive(Parser, Debug)]
pub struct ExecuteOpts {
    #[clap(flatten)]
    pub login: LoginConfig,

    #[clap(short, long = "input-value")]
    pub inputs: Vec<String>,

    #[clap(long)]
    pub ignore_sync: bool,

    #[clap()]
    pub templates: Vec<PathBuf>,
}

impl ExecuteOpts {
    pub async fn run(&self) -> Result<()> {
        let mapped_inputs = self
            .inputs
            .iter()
            .filter_map(|v| v.split_once('='))
            .collect::<HashMap<&str, &str>>();
        let mut user = self.login.client().await?;

        let sync_state = user.start_sync();

        if !self.ignore_sync {
            let mut is_synced = sync_state.first_synced_rx();
            while is_synced.next().await != Some(true) {} // let's wait for it to have synced
        }

        for tmpl_path in self.templates.iter() {
            let template = fs::read_to_string(tmpl_path)?;

            let mut tmpl_engine = user.template_engine(&template).await?;
            let input_values = {
                tmpl_engine
                    .requested_inputs()
                    .iter()
                    .map(|(key, input)| (key.clone(), (input.is_required(), input.is_space())))
                    .collect::<Vec<_>>()
            };
            for (key, (is_required, is_space)) in input_values {
                if let Some(res) = mapped_inputs.get(key.as_str()) {
                    if !is_space {
                        bail!("{key} : non-space input values not yet supported");
                    }
                    tmpl_engine.add_ref(key.to_string(), "space".to_owned(), res.to_string())?;
                } else if is_required {
                    if key != "main" {
                        bail!("Missing required input value {key} for {tmpl_path:?}");
                    }
                    info!("Main user has been provided, ignoring.")
                } else {
                    info!("No value provided for {key} for for {tmpl_path:?}");
                }
            }

            let exec_stream = tmpl_engine.execute()?;
            pin_mut!(exec_stream);
            while let Some(i) = exec_stream.next().await {
                i?
            }
        }
        Ok(())
    }
}
