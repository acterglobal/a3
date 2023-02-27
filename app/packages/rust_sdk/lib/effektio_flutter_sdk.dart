import 'dart:async';
import 'dart:core';
import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:io';

import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

export './effektio_flutter_sdk_ffi.dart' show Client;

// class EffektioClient extends ChangeNotifier {
//   final Client client;
//   EffektioClient(this.client);
// }

const defaultServer = String.fromEnvironment(
  'DEFAULT_EFFEKTIO_SERVER',
  defaultValue: 'https://matrix.effektio.org',
);

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

class EffektioSdk {
  static EffektioSdk? _instance;
  late final ffi.Api _api;
  final int _index = 0;
  final List<ffi.Client> _clients = [];
  static const platform = MethodChannel('effektio_flutter_sdk');

  EffektioSdk._(this._api);

  Future<void> _persistSessions() async {
    List<String> sessions = [];
    for (var c in _clients) {
      String token = await c.restoreToken();
      sessions.add(token);
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('sessions', sessions);
  }

  Future<void> _restore() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> sessions = (prefs.getStringList('sessions') ?? []);
    bool loggedIn = false;
    for (var token in sessions) {
      ffi.Client client = await _api.loginWithToken(appDocPath, token);
      _clients.add(client);
      loggedIn = client.loggedIn();
    }

    if (_clients.isEmpty) {
      ffi.Client client = await _api.guestClient(
        appDocPath,
        defaultServer,
        deviceName,
      );
      _clients.add(client);
      loggedIn = client.loggedIn();
      await _persistSessions();
    }
    debugPrint('Restored $_clients: $loggedIn');
  }

  Future<ffi.Client> get currentClient async {
    return _clients[_index];
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
    } catch (_) {
      try {
        // android api 23 is working here
        final String? nativeLibDir = await _getNativeLibraryDirectory();
        return DynamicLibrary.open('$nativeLibDir/$libName');
      } catch (_) {
        try {
          final PackageInfo pkgInfo = await PackageInfo.fromPlatform();
          final String pkgName = pkgInfo.packageName;
          return DynamicLibrary.open('/data/data/$pkgName/$libName');
        } catch (_) {
          rethrow;
        }
      }
    }
  }

  static String get deviceName {
    String versionName = const String.fromEnvironment(
      'VERSION_NAME',
      defaultValue: 'DEV',
    );
    return 'Effektio ${Platform.operatingSystem} $versionName';
  }

  static Future<EffektioSdk> get instance async {
    if (_instance == null) {
      final api = Platform.isAndroid
          ? ffi.Api(await _getAndroidDynLib('libeffektio.so'))
          : ffi.Api.load();
      Directory appDocDir = await getApplicationDocumentsDirectory();
      try {
        if (Platform.isAndroid) {
          api.initLogging(
            'com.example.effektio',
            appDocDir.path,
            'warn,effektio=debug',
          );
        } else if (Platform.isIOS || Platform.isMacOS) {
          api.initLogging(
            'org.effektio.app',
            appDocDir.path,
            'warn,effektio=debug',
          );
        } else {
          api.initLogging(
            'effektio',
            appDocDir.path,
            'warn,effektio=debug',
          );
        }
      } catch (e) {
        developer.log(
          'Logging setup failed',
          level: 900, // warning
          error: e,
        );
      }
      _instance = EffektioSdk._(api);
      await _instance!._restore();
    }
    return _instance!;
  }

  Future<ffi.Client> login(String username, String password) async {
    // To be removed when client management is implemented.
    for (final client in _clients) {
      if (client.userId().toString() == username) {
        return client;
      }
    }

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    final client = await _api.loginNewClient(
      appDocPath,
      username,
      password,
      deviceName,
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

  Future<void> logout() async {
    // remove current client from list
    var client = _clients.removeAt(0);
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
    if (_clients.isEmpty) {
      // login as guest
      await _restore();
    }
  }

  Future<ffi.Client> signUp(
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

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    final client = await _api.registerWithRegistrationToken(
      appDocPath,
      username,
      password,
      token,
      deviceName,
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

  ffi.CreateGroupSettings newGroupSettings(String name) {
    return _api.newGroupSettings(name);
  }

  Future<bool> reportBug(String text, String label, bool withLog) async {
    const url = String.fromEnvironment(
      'RAGESHAKE_URL',
      defaultValue: 'http://localhost/api/submit',
    );
    const username = String.fromEnvironment(
      'RAGESHAKE_USERNAME',
      defaultValue: 'alice',
    );
    const password = String.fromEnvironment(
      'RAGESHAKE_PASSWORD',
      defaultValue: 'secret',
    );
    const appName = String.fromEnvironment(
      'ISSUE_APP_NAME',
      defaultValue: 'a3-nightly',
    );
    const version = String.fromEnvironment(
      'ISSUE_APP_VERSION',
      defaultValue: '1.0.0',
    );
    return await _api.reportBug(
      url,
      username,
      password,
      appName,
      version,
      text,
      label,
      withLog,
    );
  }
}
