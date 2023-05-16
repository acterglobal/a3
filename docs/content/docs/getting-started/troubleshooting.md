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

The current system has a problem with the latest android native development kit (NDK), please downgrade to version r22.\* - then things should be fine.

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

### Flutter package `file_picker` error in android 6.0

`FilePickerDelegate` occurs error in `getSlotFromBufferLocked()` under android 6.0.
This issue was fixed android 7.0.
Please read [this comment](https://ubidots.com/community/t/solved-android-send-call-data-to-ubidots-etslotfrombufferlocked-unknown-buffer/334/2).
Now minimum version of android is 7.0.

## iOS Build

The iOS build doesn't work right now, see [#10](https://github.com/acterglobal/a3/issues/10). Please install the Android SDK and use the aformentioned emulator for development and testing.

The following is iOS build steps.
Unlike android, ios needs small space of 2~3 GB.

1. Install `flutter v2.10.5`. `v3+` seems to have some problem in macos.
2. Install the latest version of `rust`.
3. Install `cargo-make`.
4. Run `cargo make ios` in root directory of this project.
5. Run `flutter pub get` in `app` directory of this project.
6. Uncomment `# platform :ios, '9.0'` in Podfile of `app/ios` directory.
7. Run `flutter run`.

### CocoaPods issue in iOS build

You may get the error message `Invalid argument @ io_fread` during compilation of rust library.
`cocoapods` is using `ruby-macho` and `ruby-macho` occurs the crash about big input file.
iOS simulator uses `x86_64-apple-ios` architecture.
The size of our library `libacter.a` is as following:
Debug build: 717MB
Release build: 223MB
When using release build of `libacter.a`, the error `Invalid argument @ io_fread` disappeared.
The compile command of release build is the following:
`cargo make --profile release ios`
## Resolving package `intl 0.18` fails

If you see
```
Resolving dependencies...
Because acter depends on flutter_localizations from sdk which depends on intl 0.18.0, intl 0.18.0 is required.
So, because acter depends on intl 0.17.0, version solving failed.
Exited (1)
```

You are using Flutter 3.10 while we only support 3.7 so far. See [Flutter 3.10 issue](#flutter-3-10-issue).

## Flutter 3.10 issue

`Github` is using the latest version of flutter (`3.10` as of 5/11/2023).
Many packages (incl. `intl`) are not ready for `3.10`, so we can't use `flutter 3.10`.
(Our project is using `flutter_localizations` and it is using `intl`.)
We continue to use `flutter 3.7.12` unless they are not ready.

Please run `flutter --version` and if current version is greater than `3.7`, reinstall `3.7.12`.
Try running `flutter downgrade 3.7.12`. That, however, seems to not be supported for all platforms. So, if it fails, you have to delete `3.10` and install `3.7` newly.
