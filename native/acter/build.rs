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

    setup_x86_64_android_workaround();

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

fn setup_x86_64_android_workaround() {
    // FIXME: hack to ensure that sqlite compiles correctly for android x86_64bit emulator versions
    //        see https://github.com/rusqlite/rusqlite/issues/1380#issuecomment-1689765485
    let target_os = std::env::var("CARGO_CFG_TARGET_OS").expect("CARGO_CFG_TARGET_OS not set");
    let target_arch =
        std::env::var("CARGO_CFG_TARGET_ARCH").expect("CARGO_CFG_TARGET_ARCH not set");
    if target_arch == "x86_64" && target_os == "android" {
        let android_ndk_home = std::env::var("ANDROID_NDK_HOME").expect("ANDROID_NDK_HOME not set");
        let build_os = match std::env::consts::OS {
            "linux" => "linux",
            "macos" => "darwin",
            "windows" => "windows",
            _ => panic!(
                "Unsupported OS. You must use either Linux, MacOS or Windows to build the crate."
            ),
        };
        const DEFAULT_CLANG_VERSION: &str = "14.0.7";
        let clang_version =
            std::env::var("NDK_CLANG_VERSION").unwrap_or_else(|_| DEFAULT_CLANG_VERSION.to_owned());
        let linux_x86_64_lib_dir = format!(
            "toolchains/llvm/prebuilt/{build_os}-x86_64/lib64/clang/{clang_version}/lib/linux/"
        );
        println!("cargo:rustc-link-search={android_ndk_home}/{linux_x86_64_lib_dir}");
        println!("cargo:rustc-link-lib=static=clang_rt.builtins-x86_64-android");
    }
}
