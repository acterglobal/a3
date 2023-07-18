use anyhow;
use clap::Parser;
use std::{fs::read_dir, io::Write, path::PathBuf};

/// Simple program to greet a person
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// The folder to read the files from
    #[arg(short, long, default_value = ".changes")]
    input_folder: PathBuf,

    /// Target file. Will be hard overwritten
    #[arg(short, long, default_value = "Changes.md")]
    output: PathBuf,

    /// Use a git-compare and only include files added/changed
    /// since the given tag.
    #[arg(short, long)]
    since: Option<String>,
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();
    let mut writer = std::fs::File::create(args.output)?;
    for entry in read_dir(args.input_folder)? {
        let file = entry?;
        if file.metadata()?.is_file() {
            let content = std::fs::read(file.path())?;
            writer.write(&content)?;
            write!(writer, "\n")?;
        }
    }
    Ok(())
}
