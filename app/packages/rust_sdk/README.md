# acter_flutter_sdk

## IOS

Ios setup is incomplete as of now. These are the things that need to be done in order to link the native lib with ios:

1. Generate bindings to be used during static linking.
2. Configure the podspec to use the libacter.a during static linking the dependent app.

The first could be done with `ffi-gen`. The second step might require adding `LIBRARY_SEARCH_PATH` entries to `s.user_target_xcconfig`.
There is also a thing called frameworks that could be used for dynamic linking in our ios app. Generating headers will not be necessary if we decide to go that route. It would be better if we figure out the entire process before modifying `ffi-gen`.

### Useful links:

Linking rust libraries to ios apps. This article describes all the project configuration that needs to be done when linking a static library. We need to figure out how to do all this using cocoapod configuration: https://blog.mozilla.org/data/2022/01/31/this-week-in-glean-building-and-deploying-a-rust-library-on-ios/

Creating an ios framework. Again this article shows how to do this using xcode. We need to do this using cocoapods: https://www.raywenderlich.com/17753301-creating-a-framework-for-ios
