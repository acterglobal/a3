# Effektio flutter app

## Requirements

You'll need a recent:
 - [Rustup](https://rustup.rs/) setup for Rust
 - Android NDK / XCode setup for the target - and device or simulator set up
 - [flutter](https://docs.flutter.dev/get-started/install)
 -
_Note_ on the Android NDK. [Because of a change with the paths, you need to have NDKv22 install](https://github.com/bbqsrc/cargo-ndk/issues/38) (v23 and above don't work at the moment).

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

This Code is made available under an the eventually Free Software "Effektio Source License". Tl;dr: You can use the software for personal, educational and interal usage as long as the installation stays below 100 registered users and is not available to the public. Any other installation, usage or derivation of the work requires consent by the licensor. All code is made availble under the AGPL Free Software License two years after its publication.

All contributors must agree that their code is licensed this way and that the license can be changed by the licensor. A bot on the Github Repo will track that agreement.