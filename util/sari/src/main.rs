use anyhow::Result;
use clap::Parser;

mod commands;
    

#[derive(Parser, Debug)]
enum Command {
     Build(commands::build::BuildOpts),
}

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[command(subcommand)]
    command: Command,
}


fn main() -> Result<()> {
    let args = Args::parse();
    let _ = env_logger::try_init();
    match args.command {
        Command::Build(opts) => commands::build::build(opts)
    }
}