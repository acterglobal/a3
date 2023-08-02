use anyhow::Result;
use clap::Parser;
use git2::Repository;

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

fn file_subset(reference: &str) -> Result<Vec<PathBuf>> {
    let repo = Repository::open("./")?;
    let current_head = repo
        .head()
        .and_then(|b| b.peel_to_commit())
        .and_then(|c| c.tree())?;
    let main = repo
        .resolve_reference_from_short_name(reference)
        .and_then(|d| d.peel_to_commit())
        .and_then(|c| c.tree())?;

    let diff = repo.diff_tree_to_tree(Some(&current_head), Some(&main), None)?;

    Ok(diff
        .deltas()
        .filter_map(|d| d.new_file().path())
        .filter_map(|d| {
            if d.is_file() {
                Some(d.to_path_buf())
            } else {
                None
            }
        })
        .collect::<Vec<_>>())
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();
    let _ = env_logger::try_init();
    let mut writer = std::fs::File::create(args.output)?;
    let included_files = match args.since {
        Some(e) => Some(file_subset(&e)?),
        _ => None,
    };

    log::trace!("File changes to check against: {included_files:#?}");

    for entry in read_dir(args.input_folder)? {
        let file = entry?;
        if file.metadata()?.is_file() {
            let path = file.path();
            if let Some(ref e) = included_files {
                log::trace!("Checking {path:?}");
                if !e.contains(&path) {
                    log::trace!("Skipping");
                    // skipping
                    continue;
                }
            }

            let content = std::fs::read(file.path())?;
            writer.write_all(&content)?;
            writeln!(writer)?;
        }
    }
    Ok(())
}
