+++
title = "Setting up"

sort_by = "weight"
weight = 5
template = "docs/page.html"

[extra]
toc = true
top = false
+++


## Requirements

You'll need a recent:
 - [Rustup](https://rustup.rs/) setup for Rust
 - Android NDK / XCode setup for the target - and device or simulator set up
 - [flutter](https://docs.flutter.dev/get-started/install)

_Note_ on the Android NDK. We use `cargo-ndk` internally, which we've only tested with NDK r23. If you have troubles, try removing the NDK and installing version r23.

## Setup

You need `cargo make` for managing and building the native core artefacts. Install via
`cargo install cargo-make`

Then you run the init once in the root of the repository:

`cargo make setup`

You also need to build the core SDK once first:

## Building for SDK

Whenever the native SDK changed, you need to (re)build the artifacts. To do that you can use `cargo make android`

.Note: currently only android is fully supported. Plumbing for iOS is existing but not tested, Web, Linux, Mac, Windows and are platforms have not been configured yet.

## Running the App

Once the SDK is rebuild, you can run the flutter as usual on your device or emulator per:

F5 in VS Code or `flutter run` in `app`

## Speed up Building

It takes a long time to execute full build.
You can rebuild only changes of source files to save your building time meaningfully.

`cargo make android-dev`
This will build only `x86_64` of rust library.
(build only rust) `682.6s` -> `120.31s`

`flutter run --no-build`
(only flutter changed) `85.0s` -> `42.6s`

## Running Tests

We have a test suite to run unit tests and integration tests. This is run via the CI to ensure consistency and every features is expected to add further tests to the suite. You can run the tests via:
