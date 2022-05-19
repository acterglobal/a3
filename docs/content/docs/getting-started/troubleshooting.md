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

## Emulator crash 

Please use the `Pixel 4 API 32 x86` emulator for development and testing. Other Emulators - in particular 32bit variants - have shown to be problematic.

## iOS Build

The iOS build doesn't work right now, see [#10](https://github.com/effektio/effektio/issues/10). Please install the Android SDK and use the aformentioned emulator for development and testing.