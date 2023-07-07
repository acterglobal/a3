import 'dart:async';
import 'dart:core';
import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:io';

import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

export './acter_flutter_sdk_ffi.dart' show Client;

const rustLogKey = 'RUST_LOG';

const defaultServerUrl = String.fromEnvironment(
  'DEFAULT_HOMESERVER_URL',
  defaultValue: 'https://matrix.acter.global',
);

const defaultServerName = String.fromEnvironment(
  'DEFAULT_HOMESERVER_NAME',
  defaultValue: 'acter.global',
);

const defaultLogSetting = String.fromEnvironment(
  rustLogKey,
  defaultValue: 'warn,acter=debug',
);

const defaultSessionKey = String.fromEnvironment(
  'DEFAULT_ACTER_SESSION',
  defaultValue: 'sessions',
);

// ex: a3-nightly or acter-linux
String appName = String.fromEnvironment(
  'RAGESHAKE_APP_NAME',
  defaultValue: 'acter-${Platform.operatingSystem}',
);

const versionName = String.fromEnvironment(
  'RAGESHAKE_APP_VERSION',
  defaultValue: 'DEV',
);

String userAgent = '$appName/$versionName';

Color convertColor(ffi.EfkColor? primary, Color fallback) {
  if (primary == null) {
    return fallback;
  }
  var data = primary.rgbaU8();
  return Color.fromARGB(
    data[3],
    data[0],
    data[1],
    data[2],
  );
}

Completer<SharedPreferences>? _sharedPrefCompl;
Completer<String>? _appDirCompl;
Completer<ActerSdk>? _instanceCompl;

Future<String> appDir() async {
  if (_appDirCompl == null) {
    Completer<String> completer = Completer();
    completer.complete(appDirInner());
    _appDirCompl = completer;
  }
  return _appDirCompl!.future;
}

Future<String> appDirInner() async {
  Directory appDocDir = await getApplicationSupportDirectory();
  if (versionName == 'DEV') {
    // on dev we put this into a subfolder to separate from any installed version
    appDocDir = Directory(p.join(appDocDir.path, 'DEV'));
    if (!await appDocDir.exists()) {
      await appDocDir.create();
    }
  }
  return appDocDir.path;
}

Future<SharedPreferences> sharedPrefs() async {
  if (_sharedPrefCompl == null) {
    if (versionName == 'DEV') {
      // on dev we put this into a prefix to separate from any installed version
      SharedPreferences.setPrefix('dev.flutter');
    }
    final Completer<SharedPreferences> completer =
        Completer<SharedPreferences>();
    completer.complete(SharedPreferences.getInstance());
    _sharedPrefCompl = completer;
  }

  return _sharedPrefCompl!.future;
}

/// Convert an future of a FfiBufferUint8 (which you commonly get for images) to
/// a flutter ImageProvider.
///
/// `cacheHeight` and `cacheWidth` are passed to `ResizeImage` if given, allowing
/// you to control the memory used up. With the handy `cacheSize` you can overwrite
/// both values at once - this takes precedence.
Future<ImageProvider<Object>?> remapToImage(
  Future<ffi.FfiBufferUint8?> fut, {
  int? cacheSize,
  int? cacheWidth,
  int? cacheHeight,
}) async {
  if (cacheSize != null) {
    cacheHeight = cacheSize;
    cacheWidth = cacheSize;
  }
  try {
    final buffered = (await fut)!.asTypedList();
    final image = MemoryImage(buffered);
    if (cacheHeight != null || cacheWidth != null) {
      return ResizeImage(image, width: cacheWidth, height: cacheHeight);
    }
    return image;
  } catch (e) {
    debugPrint('Error fetching avatar: $e');
    return null;
  }
}

DateTime toDartDatetime(ffi.UtcDateTime dt) {
  return DateTime.fromMillisecondsSinceEpoch(dt.timestampMillis(), isUtc: true);
}

class ActerSdk {
  late final ffi.Api _api;
  static String _sessionKey = defaultSessionKey;
  int _index = 0;
  static final List<ffi.Client> _clients = [];
  static const platform = MethodChannel('acter_flutter_sdk');

  ActerSdk._(this._api);

  Future<void> _persistSessions() async {
    List<String> sessions = [];
    for (final c in _clients) {
      String token = await c.restoreToken();
      sessions.add(token);
    }
    print("setting sessions: $sessions");
    SharedPreferences prefs = await sharedPrefs();
    await prefs.setStringList(_sessionKey, sessions);
    await prefs.setInt('$_sessionKey::currentClientIdx', _index);
  }

  static Future<void> resetSessionsAndClients(String sessionKey) async {
    await _unrestoredInstance;
    _clients.clear();
    _sessionKey = sessionKey;
    SharedPreferences prefs = await sharedPrefs();
    await prefs.setStringList(_sessionKey, []);
  }

  Future<void> _restore() async {
    String appDocPath = await appDir();
    debugPrint('loading configuration from $appDocPath');
    SharedPreferences prefs = await sharedPrefs();
    List<String> sessions = (prefs.getStringList(_sessionKey) ?? []);
    bool loggedIn = false;
    for (var token in sessions) {
      ffi.Client client = await _api.loginWithToken(appDocPath, token);
      _clients.add(client);
      loggedIn = client.loggedIn();
    }
    _index = prefs.getInt('$_sessionKey::currentClientIdx') ?? 0;
    debugPrint('Restored $_clients: $loggedIn');
  }

  ffi.Client? get currentClient {
    if (_index >= 0 && _index < _clients.length) {
      return _clients.elementAt(_index);
    }
    return null;
  }

  Future<ffi.Client> newGuestClient({
    String? serverName,
    String? serverUrl,
    bool setAsCurrent = false,
  }) async {
    String appDocPath = await appDir();
    ffi.Client client = await _api.guestClient(
      appDocPath,
      serverName ?? defaultServerName,
      serverUrl ?? defaultServerUrl,
      userAgent,
    );
    _clients.add(client);
    await _persistSessions();
    if (setAsCurrent) {
      _index = _clients.length - 1;
    }
    return client;
  }

  bool get hasClients {
    return _clients.isNotEmpty;
  }

  static Future<String> _getNativeLibraryDirectory() async {
    String libDir;
    try {
      libDir = await platform.invokeMethod('getNativeLibraryDirectory');
    } on PlatformException {
      libDir = '';
    }
    return libDir;
  }

  static Future<DynamicLibrary> _getAndroidDynLib(String libName) async {
    try {
      // android api 30 is working here
      return DynamicLibrary.open(libName);
    } catch (e1) {
      debugPrint('DynamicLibrary.open by lib name failed: $e1');
      try {
        // android api 23 is working here
        final String? nativeLibDir = await _getNativeLibraryDirectory();
        return DynamicLibrary.open('$nativeLibDir/$libName');
      } catch (e2) {
        debugPrint('DynamicLibrary.open from /data/app failed: $e2');
        try {
          // android api 8 (2010) is working here
          final PackageInfo pkgInfo = await PackageInfo.fromPlatform();
          final String pkgName = pkgInfo.packageName;
          return DynamicLibrary.open('/data/data/$pkgName/$libName');
        } catch (e3) {
          debugPrint('DynamicLibrary.open from /data/data failed: $e3');
          rethrow;
        }
      }
    }
  }

  static Future<ActerSdk> _unrestoredInstanceInner() async {
    final api = Platform.isAndroid
        ? ffi.Api(await _getAndroidDynLib('libacter.so'))
        : ffi.Api.load();
    String appPath = await appDir();

    String logSettings =
        (await sharedPrefs()).getString(rustLogKey) ?? defaultLogSetting;
    try {
      api.initLogging(appPath, logSettings);
    } catch (e) {
      developer.log(
        'Logging setup failed',
        level: 900, // warning
        error: e,
      );
    }
    return ActerSdk._(api);
  }

  static Future<ActerSdk> get _unrestoredInstance async {
    if (_instanceCompl == null) {
      Completer<ActerSdk> completer = Completer();
      completer.complete(_unrestoredInstanceInner());
      _instanceCompl = completer;
    }
    return _instanceCompl!.future;
  }

  static Future<ActerSdk> get instance async {
    final instance = await _unrestoredInstance;
    if (!instance.hasClients) {
      await instance._restore();
    }
    return instance;
  }

  Future<ffi.Client> login(String username, String password) async {
    // To be removed when client management is implemented.
    for (final client in _clients) {
      if (client.userId().toString() == username) {
        return client;
      }
    }

    String appDocPath = await appDir();
    final client = await _api.loginNewClient(
      appDocPath,
      username,
      password,
      defaultServerName,
      defaultServerUrl,
      userAgent,
    );
    if (_clients.length == 1 && _clients[0].isGuest()) {
      // we are replacing a guest account
      var client = _clients.removeAt(0);
      unawaited(
        client.logout().catchError((e) {
          developer.log(
            'Logout of Guest failed',
            level: 900, // warning
            error: e,
          );
          return e is int;
        }),
      ); // Explicitly-ignored fire-and-forget.
    }
    _clients.add(client);
    await _persistSessions();
    return client;
  }

  Future<bool> logout() async {
    // remove current client from list
    final client = _clients.removeAt(_index);
    _index = _index > 0 ? _index - 1 : 0;
    print("Remainig clients $_clients");
    await _persistSessions();
    unawaited(
      client.logout().catchError((e) {
        developer.log(
          'Logout failed',
          level: 900, // warning
          error: e,
        );
        return e is int;
      }),
    ); // Explicitly-ignored fire-and-forget.
    return _clients.isNotEmpty;
  }

  Future<ffi.Client> register(
    String username,
    String password,
    String displayName,
    String token,
  ) async {
    // To be removed when client management is implemented.
    for (final client in _clients) {
      if (client.userId().toString() == username) {
        return client;
      }
    }

    String appDocPath = await appDir();
    final client = await _api.registerWithToken(
      appDocPath,
      username,
      password,
      token,
      defaultServerName,
      defaultServerUrl,
      userAgent,
    );
    final account = client.account();
    await account.setDisplayName(displayName);
    if (_clients.length == 1 && _clients[0].isGuest()) {
      // we are replacing a guest account
      _clients.removeAt(0);
    }
    _clients.add(client);
    await _persistSessions();
    return client;
  }

  List<ffi.Client> get clients {
    return _clients;
  }

  ffi.CreateSpaceSettings newSpaceSettings(
    String name,
    String? description,
    String? avatarUri,
    String? parent,
  ) {
    return _api.newSpaceSettings(name, description, avatarUri, parent);
  }

  String rotateLogFile() {
    return _api.rotateLogFile();
  }

  void writeLog(String text, String level) {
    _api.writeLog(text, level);
  }
}
