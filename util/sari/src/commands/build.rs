use std::path::PathBuf;
use anyhow::Result;

use clap::Parser;


#[derive(Parser, Debug)]
pub struct BuildOpts {
    #[arg(long, default_value = "./native/acter/src/acter.udl")]
    udl_path: String,

    #[arg(long, default_value = "./native/acter/uniffi.toml")]
    uniffi_toml: String,

    #[arg(long, default_value = "./packages/rust_sdk/lib/")]
    out_dir: String,

    #[arg(long, default_value = "./packages/rust_sdk/linux/libacter.so")]
    lib_path: String,
}


pub fn build(opts: BuildOpts) -> Result<()> {
    uniffi_dart::r#gen::generate_dart_bindings(
        opts.udl_path.as_str().into(),
        
        Some(opts.uniffi_toml.as_str().into()),
        Some(opts.out_dir.as_str().into()),
        // None,
        Some(opts.lib_path.as_str().into()),
    )?;
    Ok(())
}