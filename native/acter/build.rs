use ffi_gen::FfiGen;
use std::env;
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
    // FIXME: hack to ensure that sqlite compiles correctly for android x86_64bit emulator versions
    //        see https://github.com/rusqlite/rusqlite/issues/1380#issuecomment-1689765485
    let target = env::var("TARGET").unwrap();
    if target == "x86_64-linux-android" {
        let ndk_home = env::var("ANDROID_NDK_HOME").expect(
            "ANDROID_NDK_HOME variable needs to be set for us to build for x86_64-linux-android ",
        );
        println!("cargo:rustc-link-lib=static=clang_rt.builtins-x86_64-android");
        println!("cargo:rustc-link-search={ndk_home}/25.2.9519653/toolchains/llvm/prebuilt/linux-x86_64/lib64/clang/14.0.7/lib/linux");
    }

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
            .generate_dart(dart, "acter", "acter")
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
