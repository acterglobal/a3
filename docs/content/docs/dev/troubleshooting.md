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

This'll ensure the flutter to look for the second option of JDK path which is `$JAVA_HOME`. And can be confirmed with `flutter doctor --v` output.

## Doesn't build on Linux: linker failed

Run this with `--verbose`. If the specific method you are seeing is something along the lines of:

```
[   +5 ms] : && /snap/flutter/current/usr/bin/clang++  -g  -B/snap/flutter/current/usr/lib/gcc/x86_64-linux-gnu/9
-B/snap/flutter/current/usr/lib/x86_64-linux-gnu -B/snap/flutter/current/lib/x86_64-linux-gnu -B/snap/flutter/current/usr/lib/
-L/snap/flutter/current/usr/lib/gcc/x86_64-linux-gnu/9 -L/snap/flutter/current/usr/lib/x86_64-linux-gnu -L/snap/flutter/current/lib/x86_64-linux-gnu
-L/snap/flutter/current/usr/lib/ -lblkid -lgcrypt -llzma -llz4 -lgpg-error -luuid -lpthread -ldl -lepoxy -lfontconfig CMakeFiles/acter.dir/main.cc.o
CMakeFiles/acter.dir/my_application.cc.o CMakeFiles/acter.dir/flutter/generated_plugin_registrant.cc.o  -o intermediates_do_not_run/acter
-Wl,-rpath,/DEV/acter/a3/app/build/linux/x64/debug/plugins/acter_flutter_sdk:/DEV/acter/a3/app/build/linux/x64/debug/plugins/emoji_picker_flutter:/DEV/ac
ter/a3/app/build/linux/x64/debug/plugins/file_selector_linux:/DEV/acter/a3/app/build/linux/x64/debug/plugins/flutter_secure_storage_linux:/DEV/acter/a3/a
pp/build/linux/x64/debug/plugins/url_launcher_linux:/DEV/acter/a3/app/linux/flutter/ephemeral:  plugins/acter_flutter_sdk/libacter_flutter_sdk_plugin.so
plugins/emoji_picker_flutter/libemoji_picker_flutter_plugin.so  plugins/file_selector_linux/libfile_selector_linux_plugin.so
plugins/flutter_secure_storage_linux/libflutter_secure_storage_linux_plugin.so  plugins/url_launcher_linux/liburl_launcher_linux_plugin.so
/DEV/acter/a3/app/linux/flutter/ephemeral/libflutter_linux_gtk.so  /snap/flutter/current/usr/lib/x86_64-linux-gnu/libgtk-3.so
/snap/flutter/current/usr/lib/x86_64-linux-gnu/libgdk-3.so  /snap/flutter/current/usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so
/snap/flutter/current/usr/lib/x86_64-linux-gnu/libpango-1.0.so  /snap/flutter/current/usr/lib/x86_64-linux-gnu/libharfbuzz.so
/snap/flutter/current/usr/lib/x86_64-linux-gnu/libatk-1.0.so  /snap/flutter/current/usr/lib/x86_64-linux-gnu/libcairo-gobject.so
/snap/flutter/current/usr/lib/x86_64-linux-gnu/libcairo.so  /snap/flutter/current/usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so
/snap/flutter/current/usr/lib/x86_64-linux-gnu/libgio-2.0.so  /snap/flutter/current/usr/lib/x86_64-linux-gnu/libgobject-2.0.so
/snap/flutter/current/usr/lib/x86_64-linux-gnu/libglib-2.0.so && :
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libcrypto.so.3: undefined reference to `pthread_setspecific@GLIBC_2.34'
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libtss2-esys.so.0: undefined reference to `dlopen@GLIBC_2.34'
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libcrypto.so.3: undefined reference to `pthread_rwlock_init@GLIBC_2.34'
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libcrypto.so.3: undefined reference to `pthread_rwlock_wrlock@GLIBC_2.34'
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libtss2-esys.so.0: undefined reference to `dlerror@GLIBC_2.34'
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libcrypto.so.3: undefined reference to `__isoc23_strtol@GLIBC_2.38'
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libcrypto.so.3: undefined reference to `pthread_getspecific@GLIBC_2.34'
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libsecret-1.so.0: undefined reference to `g_task_set_static_name'
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libtss2-esys.so.0: undefined reference to `dlclose@GLIBC_2.34'
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libcrypto.so.3: undefined reference to `pthread_rwlock_rdlock@GLIBC_2.34'
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libcrypto.so.3: undefined reference to `pthread_key_delete@GLIBC_2.34'
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libcrypto.so.3: undefined reference to `fstat@GLIBC_2.33'
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libcrypto.so.3: undefined reference to `stat@GLIBC_2.33'
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libcrypto.so.3: undefined reference to `pthread_once@GLIBC_2.34'
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libcrypto.so.3: undefined reference to `dladdr@GLIBC_2.34'
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libcrypto.so.3: undefined reference to `pthread_rwlock_destroy@GLIBC_2.34'
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libcrypto.so.3: undefined reference to `pthread_key_create@GLIBC_2.34'
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libcrypto.so.3: undefined reference to `pthread_rwlock_unlock@GLIBC_2.34'
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libtss2-esys.so.0: undefined reference to `dlsym@GLIBC_2.34'
[        ] /snap/flutter/current/usr/bin/ld: /lib64/libsecret-1.so.0: undefined reference to `g_memdup2'
[        ] clang: error: linker command failed with exit code 1 (use -v to see invocation)
[   +1 ms] ninja: build stopped: subcommand failed.
[  +10 ms] Building Linux application... (completed in 24,2s)
[        ] Exception: Build process failed
[   +3 ms] "flutter run" took 25.158ms.
[   +3 ms]
           #0      throwToolExit (package:flutter_tools/src/base/common.dart:10:3)
           #1      RunCommand.runCommand (package:flutter_tools/src/commands/run.dart:760:9)
           <asynchronous suspension>
           #2      FlutterCommand.run.<anonymous closure> (package:flutter_tools/src/runner/flutter_command.dart:1297:27)
           <asynchronous suspension>
           #3      AppContext.run.<anonymous closure> (package:flutter_tools/src/base/context.dart:150:19)
           <asynchronous suspension>
           #4      CommandRunner.runCommand (package:args/command_runner.dart:212:13)
           <asynchronous suspension>
           #5      FlutterCommandRunner.runCommand.<anonymous closure> (package:flutter_tools/src/runner/flutter_command_runner.dart:339:9)
           <asynchronous suspension>
           #6      AppContext.run.<anonymous closure> (package:flutter_tools/src/base/context.dart:150:19)
           <asynchronous suspension>
           #7      FlutterCommandRunner.runCommand (package:flutter_tools/src/runner/flutter_command_runner.dart:285:5)
           <asynchronous suspension>
           #8      run.<anonymous closure>.<anonymous closure> (package:flutter_tools/runner.dart:115:9)
           <asynchronous suspension>
           #9      AppContext.run.<anonymous closure> (package:flutter_tools/src/base/context.dart:150:19)
           <asynchronous suspension>
           #10     main (package:flutter_tools/executable.dart:90:3)
           <asynchronous suspension>


[ +106 ms] ensureAnalyticsSent: 101ms
[        ] Running 1 shutdown hook
[  +12 ms] Shutdown hooks complete
[        ] exiting with code 1
```

It is [a known, unresolved issue of flutter in snap](https://github.com/flutter/flutter/issues/64348) when used [with `flutter_secure_storage`](https://github.com/mogol/flutter_secure_storage/issues/314). Unfortunately at this point the only way to get around that is to use a non-snap-version of flutter. Try removing flutter from snap via

```
sudo snap remove flutter
```

And install it using the native system tools or [install flutter manually](https://docs.flutter.dev/get-started/install/linux#method-2-manual-installation).
