use std::fs;
use std::path::{Path, PathBuf};

use flutter_rust_bridge_codegen::{
    commands, generator_dart, generator_rust, parser, transformer, utils::mod_from_rust_path,
};

fn main() {
    let crate_dir = std::env::var("CARGO_MANIFEST_DIR").expect("Only run from within cargo");
    let rust_input_path = format!("{}/src/api.rs", crate_dir);
    let rust_output_path = format!("{}/src/bridge_generated.rs", crate_dir);

    let source_rust_content =
        fs::read_to_string(rust_input_path.clone()).expect("Can't read src/api.rs");
    let file_ast = syn::parse_file(&source_rust_content).expect("parsing src/api.rs failed");

    let raw_api_file = parser::parse(&source_rust_content, file_ast);
    let api_file = transformer::transform(raw_api_file);
    let generated_rust =
        generator_rust::generate(&api_file, &mod_from_rust_path(&rust_input_path, &crate_dir));
    //fs::create_dir_all(&rust_output_dir).unwrap();
    fs::write(&rust_output_path, generated_rust.code).expect("Writing generated file failed");
    // commands::format_rust(&rust_output_path);

    // let (generated_dart_file_prelude, generated_dart_decl_raw, generated_dart_impl_raw) =
    //     generator_dart::generate(
    //         &api_file,
    //         &config.dart_api_class_name(),
    //         &config.dart_api_impl_class_name(),
    //         &config.dart_wire_class_name(),
    //     );
}
