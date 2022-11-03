use ffi_gen::FfiGen;
use std::path::PathBuf;

static API_DESC_FILENAME: &str = "api.rsh";
static API_DART_FILENAME: &str = "bindings.dart";
static API_RUST_FILENAME: &str = "api_generated.rs";

fn main() {
    let crate_dir = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap());
    let path = crate_dir.join(API_DESC_FILENAME);
    println!(
        "cargo:rerun-if-changed={}",
        path.as_path().to_str().unwrap()
    );

    if std::env::var("SKIP_FFIGEN").is_err() && std::env::var("CARGO_FEATURE_DART").is_ok() {
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

    // let js = dir.join("bindings.mjs");
    // ffigen.generate_js(js).unwrap();
    // let ts = dir.join("bindings.d.ts");
    // ffigen.generate_ts(ts).unwrap();
}
