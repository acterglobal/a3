+++
title = "Troubleshooting"

sort_by = "weight"
weight = 10
template = "docs/page.html"

[extra]
toc = true
top = false
+++


## NDK compile error

The current system has a problem with the latest android native development kit (NDK), please downgrade to version r22.* - then things should be fine.

## Android Build in Windows

1. 35GB of HDD needed for project building. It doesn't cover android emulator vm.
2. Run `cargo install cargo-make` so that `cargo make` can be executed.
3. Run `cargo make android` in root directory.
4. Open sdk manager in android studio and install `Google Play x86_64 API 30` image and `Android SDK Platform 30`.
  - `API 31+` image is not launching in windows for now.
  - This apk is not working on `x86` image of `API 30`.
  - `API 32` doesn't contain `x86` image now.
5. Open virtual device manager in android studio and create vm using `Google Play x86_64 API 30` image.
  - 4GB of internal storage is recommended, because apk size of this project is 500+MB.
6. Launch android emulator.
7. Change to `app` directory and run `flutter run`.

## iOS Build

The iOS build doesn't work right now, see [#10](https://github.com/effektio/effektio/issues/10). Please install the Android SDK and use the aformentioned emulator for development and testing.

The following is iOS build steps.
Unlike android, ios needs small space of 2~3 GB.

1. Install `flutter v2.10.5`. `v3+` seems to have some problem in macos.
2. Install the latest version of `rust`.
3. Install `cargo-make`.
4. Run `cargo make ios` in root directory of this project.
5. Run `flutter pub get` in `app` directory of this project.
6. Uncomment `# platform :ios, '9.0'` in Podfile of `app/ios` directory.
7. Run `flutter run`.

## Flutter package `file_picker` error in android 6.0

`FilePickerDelegate` occurs error in `getSlotFromBufferLocked()` under android 6.0.
This issue was fixed android 7.0.
Please read [this comment](https://ubidots.com/community/t/solved-android-send-call-data-to-ubidots-etslotfrombufferlocked-unknown-buffer/334/2).
Now minimum version of android is 7.0.
