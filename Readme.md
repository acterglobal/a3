# Efektio flutter app

## Requirements

You'll need a recent:
 - [Rustup](https://rustup.rs/) setup for Rust
 - Android NDK / XCode setup for the target - and device or simulator set up
 - [flutter](https://docs.flutter.dev/get-started/install)
 -

## Setup

You need `cargo make` for managing and building the native core artefacts. Install via
`cargo install cargo-make`

Then you run the init once in the root of the repository:

`cargo make init`

You also need to build the core SDK once first:

## Building for SDK

Whenever the native SDK changed, you need to (re)build the artifacts. To do that you can use `cargo make build` with the specific SDK target, e.g. `cargo make build android`

.Note: currently only android is fully supported. Plumbing for iOS is existing but not tested, Web, Linux, Mac, Windows and are platforms have not been configured yet.

## Running the App

Once the SDK is rebuild, you can run the flutter as usual on your device or emulator per:

F5 in VS Code or `flutter run` in `app`

## Running Tests

We have a test suite to run unit tests and integration tests. This is run via the CI to ensure consistency and every features is expected to add further tests to the suite. You can run the tests via:

.... TBD

## License