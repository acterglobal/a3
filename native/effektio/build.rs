use ffi_gen::FfiGen;
use std::path::PathBuf;

static API_DESC_FILENAME: &str = "api.rsh";
static API_DART_FILENAME: &str = "bindings.dart";
static API_RUST_FILENAME: &str = "api_generated.rs";
static API_C_HEADER_FILENAME: &str = "bindings.h";
static API_CBINDGEN_CONFIG_FILENAME: &str = "cbindgen.toml";

fn main() {
    let crate_dir = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap());
    let path = crate_dir.join(API_DESC_FILENAME);
    println!(
        "cargo:rerun-if-changed={}",
        path.as_path().to_str().unwrap()
    );

    if std::env::var("SKIP_FFIGEN").is_err() {
        // general FFI-gen
        let ffigen = FfiGen::new(&path).expect("Could not parse api.rsh");
        let dart = crate_dir.join(API_DART_FILENAME);
        // building the rust source for reuse in cbindgen later
        let rst = ffigen
            .generate_rust(ffi_gen::Abi::Native64)
            .expect("Failure generating rust side of ffigen");
        std::fs::write(crate_dir.join("src").join(API_RUST_FILENAME), rst)
            .expect("Writing rust file failed.");

        // then let's build the dart API
        ffigen
            .generate_dart(dart, "effektio", "effektio")
            .expect("Failure generating dart side of ffigen");
    }

    if std::env::var("SKIP_CBINDGEN").is_err() {
        // once the setup is ready, let's create the c-headers
        // this needs the rust API to be generated first, as it
        // imports that via the `cbindings`-feature to scan an build the headers
        let config = cbindgen::Config::from_file(crate_dir.join(API_CBINDGEN_CONFIG_FILENAME))
            .expect("Reading cbindgen.toml failed");

        cbindgen::Builder::new()
            .with_config(config)
            .with_crate(crate_dir)
            .generate()
            .expect("Unable to generate C-headers")
            .write_to_file(API_C_HEADER_FILENAME);
    }

    // let js = dir.join("bindings.mjs");
    // ffigen.generate_js(js).unwrap();
    // let ts = dir.join("bindings.d.ts");
    // ffigen.generate_ts(ts).unwrap();
}
