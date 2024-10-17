# Using the Video Block plugin

The Video Block relies on the [Media Kit]() package, thus all setup that is required for its usage is also required for the usage of this plugin.

## Permissions

Depending on what platforms you intend to use Video Block with, you will have to enable these permissions for each platform.

### Android

You have to add these permissions to your `android/app/src/main/AndroidManifest.xml` (Android Manifest):

```
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.example.app">
    <application
      ...
      />
    </application>
    <!--
      Internet access permissions.
      -->
    <uses-permission android:name="android.permission.INTERNET" />
    <!--
      Media access permissions.
      Android 13 or higher.
      https://developer.android.com/about/versions/13/behavior-changes-13#granular-media-permissions
      -->
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    <!--
      Storage access permissions.
      Android 12 or lower.
      -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
</manifest>
```

If you do need to read from file, you will additionally have to handle requesting permission from the user to do so. We recommend to use the package [Permission Handler](https://pub.dev/packages/permission_handler) to achieve this.

See example:

```
if (/* Android 13 or higher. */) {
  // Video permissions.
  if (await Permission.videos.isDenied || await Permission.videos.isPermanentlyDenied) {
    final state = await Permission.videos.request();
    if (!state.isGranted) {
      await SystemNavigator.pop();
    }
  }
  // Audio permissions.
  if (await Permission.audio.isDenied || await Permission.audio.isPermanentlyDenied) {
    final state = await Permission.audio.request();
    if (!state.isGranted) {
      await SystemNavigator.pop();
    }
  }
} else {
  if (await Permission.storage.isDenied || await Permission.storage.isPermanentlyDenied) {
    final state = await Permission.storage.request();
    if (!state.isGranted) {
      await SystemNavigator.pop();
    }
  }
}
```

### iOS

You need to enable internet access in `ios/Runner/Info.plist`.

```
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### MacOS

You need to enable internet access in `macos/Runner/Release.entitlements` and `macos/Runner/DebugProfile.entitlements`

Add this to both files:

```
<key>com.apple.security.network.client</key>
<true/>
```

If you also want to support files, you should disable sandbox access to files:

```
<key>com.apple.security.app-sandbox</key>
<false/>
```

### Windows

No additional steps required for Windows support.

### GNU/Linux

No additional steps required for Linux support.

## External Libraries

If you don't intend to support GNU/Linux, you can skip this step.

See [media_kit#gnulinux](https://pub.dev/packages/media_kit#gnulinux) for more information.

### Notes

For MacOS, there will be warnings that cannot be silenced. These are **not** critical, and should be ignored.

See [media_kit#macos](https://pub.dev/packages/media_kit#macos)

## Usage

You should ensure that `MediaKit` is initialized. To do achieve this, in `main()` add these two lines before `runapp()`:

```
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  VideoBlockKit.ensureInitialized();

  runApp(const AppWidget());
}
```

Now you can enable the VideoBlockComponent similar to any other block component.
