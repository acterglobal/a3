use ffi_gen::FfiGen;
use std::path::PathBuf;

static API_DESC_FILENAME: &str = "api.rsh";

fn main() {
    let dir = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap());
    let path = dir.join(API_DESC_FILENAME);
    println!(
        "cargo:rerun-if-changed={}",
        path.as_path().to_str().unwrap()
    );
    let ffigen = FfiGen::new(&path).unwrap();
    let dart = dir.join("bindings.dart");
    let rst = ffigen.generate_rust(ffi_gen::Abi::Native64).unwrap();
    std::fs::write(dir.join("api_generated.rs"), rst).unwrap();
    ffigen.generate_dart(dart, "effektio", "effektio").unwrap();
    // let js = dir.join("bindings.mjs");
    // ffigen.generate_js(js).unwrap();
    // let ts = dir.join("bindings.d.ts");
    // ffigen.generate_ts(ts).unwrap();
}
