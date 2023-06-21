+++
title = "Troubleshooting"

weight = 10
template = "docs/page.html"

[extra]
toc = true
top = false
+++

Common problem when developing Acter and their solutions.

## `Unhandled Exception: failed to read or write to the crypto store the account in the store doesn't match the account in the constructor: expected ..:acter.global:guest_device, got ..:acter.global:guest_device

The App didn't successfully store the old token and when trying to start a fresh guest account, opening the crypto store failed. Until [#527](https://github.com/acterglobal/a3/issues/527) is fixed, you need to:

1. stop the app
2. clear the [user data](#where-is-the-user-data-stored)
3. start the app again

This should give you a fresh guest account login.

## Where is the user data stored?

We are using [`path_provider`'s `getApplicationDirectory`](https://pub.dev/packages/path_provider) to know where to store the user data. The exact folder the data is stored, is system dependent. These usually are:

- Linux: `~/.local/share/global.acter.app/` (e.g. `/home/ben/.local/share/global.acter.app/`)
- Windows: `$USERDIR\AppData\Roaming\global.acter\app` (e.g. `C:\Users\Ben\AppData\Roaming\global.acter\app`)
- MacOS: `$USER/Library/Containers/global.acter.app/` (e.g. `/Users/ben/Library/Containers/global.acter.app/`, notice that _Finder_ doesn't see the `Library` folder, you need to use the terminal to get there)

Just opening a terminal and doing `rm -rf $PATH` (where `$PATH` is the necessary path above), usually resets all locally stored data. **Careful as this also removes all locally held crypto tokens**.

## Execution failed for task ':app:processDebugMainManifest'.
> Unable to make field private final java.lang.String java.io.File.path accessible: module java.base does not "opens java.io" to unnamed module @7fbe8ef

If you happen to come across this exception while compiling Android build for application launch, the reason for that is with the flutter fetching the JDK path from Android Studio directory as a default option. This is reported to be occuring in latest **Android Studio Flamingo (2022.2.1)** in reference to the Flutter issue [#106416](https://github.com/flutter/flutter/issues/106416).

As long as you have default `$JAVA_HOME` variable set up in environment variables, you can set up flutter path for finding JDK to be:
```
flutter config --android-studio-dir=/
```
This'll ensure the flutter to look for the second option of JDK path which is `$JAVA_HOME`. And can be confirmed with ```flutter doctor --v``` output.


