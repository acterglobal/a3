// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:io';

import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:package_info/package_info.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

export './acter_flutter_sdk_ffi.dart' show Client;

final _log = Logger('a3::sdk');

const rustLogKey = 'RUST_LOG';
const proxyKey = 'HTTP_PROXY';

const defaultServerUrl = String.fromEnvironment(
  'DEFAULT_HOMESERVER_URL',
  defaultValue: 'https://matrix.m-1.acter.global',
);

const defaultServerName = String.fromEnvironment(
  'DEFAULT_HOMESERVER_NAME',
  defaultValue: 'm-1.acter.global',
);

const defaultLogSetting = String.fromEnvironment(
  rustLogKey,
  defaultValue: 'acter=debug,a3::sdk=info,a3=warn,warn',
);

const defaultSessionKey = String.fromEnvironment(
  'DEFAULT_ACTER_SESSION',
  defaultValue: 'sessions',
);

const defaultHttpProxy = String.fromEnvironment(
  proxyKey,
  defaultValue: '',
);

// allows us to use a different AppGroup Section to store
// the app group under
const appleKeychainAppGroupName = String.fromEnvironment(
  'APPLE_KEYCHAIN_APP_GROUP_NAME',
  defaultValue: 'V45JGKTC6K.global.acter.a3',
);

// ex: a3-nightly or acter-linux
const appName = String.fromEnvironment(
  'RAGESHAKE_APP_NAME',
  defaultValue: 'acter-dev',
);

const versionName = String.fromEnvironment(
  'RAGESHAKE_APP_VERSION',
  defaultValue: 'DEV',
);

const isDevBuild = versionName == 'DEV';

String userAgent = '$appName/$versionName';
RegExp logFileRegExp = RegExp('app_.*log');
RegExp screenshotFileRegExp = RegExp('screenshot_.*png');

Color convertColor(int? primary, Color fallback) =>
    Color(primary ?? fallback.value);

Completer<SharedPreferences>? _sharedPrefCompl;
Completer<String>? _appDirCompl;
Completer<String>? _appCacheDirCompl;
Completer<ActerSdk>? _unrestoredInstanceCompl;
Completer<ActerSdk>? _instanceCompl;

Future<String> appDir() async {
  if (_appDirCompl == null) {
    Completer<String> completer = Completer();
    completer.complete(appDirInner());
    _appDirCompl = completer;
  }
  return _appDirCompl!.future;
}

Future<String> appCacheDir() async {
  if (_appCacheDirCompl == null) {
    Completer<String> completer = Completer();
    completer.complete(appCacheDirInner());
    _appCacheDirCompl = completer;
  }
  return _appCacheDirCompl!.future;
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

Future<String> appCacheDirInner() async {
  Directory appCacheDir = await getApplicationCacheDirectory();
  if (versionName == 'DEV') {
    // on dev we put this into a subfolder to separate from any installed version
    appCacheDir = Directory(p.join(appCacheDir.path, 'DEV'));
    if (!await appCacheDir.exists()) {
      await appCacheDir.create();
    }
  }
  return appCacheDir.path;
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
    _log.severe('Error fetching avatar: $e');
    return null;
  }
}

DateTime toDartDatetime(ffi.UtcDateTime dt) {
  return DateTime.fromMillisecondsSinceEpoch(dt.timestampMillis(), isUtc: true);
}

const aOptions = AndroidOptions(
  encryptedSharedPreferences: true,
  preferencesKeyPrefix: isDevBuild ? 'dev.flutter' : null,
);
const iOptions = IOSOptions(
  synchronizable: false,
  accessibility: KeychainAccessibility
      .first_unlock, // must have been unlocked since reboot
  groupId:
      appleKeychainAppGroupName, // to allow the background process to access the same store
);
const mOptions = MacOsOptions(
  synchronizable: false,
  accessibility: KeychainAccessibility
      .first_unlock, // must have been unlocked since reboot
  groupId:
      appleKeychainAppGroupName, // to allow the background process to access the same store
);

class ActerSdk {
  late final ffi.Api _api;
  String? _previousLogPath;
  static String _sessionKey = defaultSessionKey;
  int _index = 0;
  static final List<ffi.Client> _clients = [];
  static const platform = MethodChannel('acter_flutter_sdk');

  static FlutterSecureStorage storage = const FlutterSecureStorage(
    aOptions: aOptions,
    iOptions: iOptions,
    mOptions: mOptions,
  );

  ActerSdk._(this._api);

  Future<void> _persistSessions() async {
    List<String> sessions = [];
    for (final c in _clients) {
      String deviceId = c.deviceId().toString();
      String token = await c.restoreToken();
      await storage.write(key: deviceId, value: token);
      sessions.add(deviceId);
    }
    await storage.write(key: _sessionKey, value: json.encode(sessions));
    final key = '$_sessionKey::currentClientIdx';
    await storage.write(key: key, value: '$_index');
    _log.info('${sessions.length} sessions stored');
  }

  static Future<void> resetSessionsAndClients(String sessionKey) async {
    await _unrestoredInstance;
    _clients.clear();
    _sessionKey = sessionKey;
    await storage.write(key: _sessionKey, value: json.encode([]));
  }

  String? get previousLogPath => _previousLogPath;

  ffi.Api get api => _api;

  Future<ffi.Client> getClientWithDeviceId(
    String deviceId,
    bool setAsCurrent,
  ) async {
    ffi.Client? client;
    int foundIdx = 0;
    for (final c in _clients) {
      if (c.deviceId().toString() == deviceId) {
        client = c;
        break;
      }
      foundIdx += 1;
    }
    if (client == null) {
      throw 'Unknown client $deviceId';
    }
    if (setAsCurrent) {
      _index = foundIdx;
    }

    return client;
  }

  Future<ffi.NotificationItem> getNotificationFor(
    String deviceId,
    String roomId,
    String eventId,
  ) async {
    final client = await getClientWithDeviceId(deviceId, false);
    return await client.getNotificationItem(roomId, eventId);
  }

  Future<void> _maybeMigrateFromPrefs(
    String appDocPath,
    String appCachePath,
  ) async {
    SharedPreferences prefs = await sharedPrefs();
    List<String> sessions = (prefs.getStringList(_sessionKey) ?? []);
    for (final token in sessions) {
      ffi.Client client =
          await _api.loginWithToken(appDocPath, appCachePath, token);
      _clients.add(client);
    }
    _index = prefs.getInt('$_sessionKey::currentClientIdx') ?? 0;
    _log.warning('Migrated $_clients');

    await _persistSessions();
    // then destroy the old records.
    await prefs.remove(_sessionKey);
    await prefs.remove('$_sessionKey::currentClientIdx');
  }

  Future<void> _restore() async {
    if (_clients.isNotEmpty) {
      _log.warning('double restore. ignore');
      return;
    }
    String appDocPath = await appDir();
    String appCachePath = await appCacheDir();
    int delayedCounter = 0;
    while (!await storage.isCupertinoProtectedDataAvailable()) {
      if (delayedCounter > 10) {
        _log.severe('Secure Store: not available after 10 seconds');
        throw 'Secure Store: not available';
      }
      delayedCounter += 1;
      _log.info('Secure Store: not available yet. Delaying');
      await Future.delayed(const Duration(milliseconds: 50));
    }

    _log.info('Secure Store: available. Attempting to read.');
    if (Platform.isAndroid) {
      // fake read for https://github.com/mogol/flutter_secure_storage/issues/566
      _log.info('Secure Store: fake read for android');
      await storage.read(key: _sessionKey);
    }
    _log.info('Secure Store: attempting to check if $_sessionKey exists');
    String? sessionsStr;
    try {
      sessionsStr = await storage.read(key: _sessionKey);
    } on PlatformException catch (error, stack) {
      if (error.code == '-25300') {
        _log.severe('Ignoring read failure for missing key $_sessionKey');
      } else {
        _log.severe(
          'Ignoring read failure of session key $_sessionKey',
          error,
          stack,
        );
      }
    } catch (error, stack) {
      _log.severe(
        'Ignoring read failure of session key $_sessionKey',
        error,
        stack,
      );
    }

    if (sessionsStr == null) {
      _log.info('Secure Store: session key not found, checking for migration');
      // not yet set. let's see if we maybe want to migrate instead:
      await _maybeMigrateFromPrefs(appDocPath, appCachePath);
      return;
    }

    _log.info('Secure Store: decoding sessions');
    final List<dynamic> sessionKeys = json.decode(sessionsStr);
    _log.info('Secure Store: decoding sessions: ${sessionKeys.length} found');
    for (final deviceId in sessionKeys) {
      _log.info('Secure Store[$deviceId]: attempting to read session');
      final token = await storage.read(key: deviceId as String);
      if (token != null) {
        _log.info('Secure Store[$deviceId]: token found');
        ffi.Client client =
            await _api.loginWithToken(appDocPath, appCachePath, token);
        _log.info('Secure Store[$deviceId]: login successful');
        _clients.add(client);
      } else {
        _log.severe(
          'Secure Store[$deviceId]: not found. despite in session list',
        );
      }
    }
    final key = await storage.read(key: '$_sessionKey::currentClientIdx');
    _index = int.tryParse(key ?? '0') ?? 0;
    _log.info('loading configuration from $appDocPath');
    _log.info('restored ${_clients.length} clients');
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
    String appCachePath = await appCacheDir();
    ffi.Client client = await _api.guestClient(
      appDocPath,
      appCachePath,
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
        final String nativeLibDir = await _getNativeLibraryDirectory();
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

  static Future<void> nuke() async {
    final instance = await _unrestoredInstance;
    await instance._nuke();
  }

  Future<void> _nuke() async {
    String appDocPath = await appDir();
    String appCachePath = await appCacheDir();
    for (var cl in _clients) {
      try {
        final userId = cl.userId().toString();
        await cl.logout();
        await _api.destroyLocalData(
          appDocPath,
          appCachePath,
          userId,
          defaultServerName,
        );
      } catch (e, s) {
        _log.severe('Error nuking', e, s);
      }
    }

    _clients.clear();
    await _persistSessions();
    try {
      // and destroy everything that is left.
      Directory(appDocPath).delete(recursive: true);
    } catch (e) {
      print('Failure deleting $appDocPath: $e');
    }
  }

  static Future<ActerSdk> _unrestoredInstanceInner() async {
    final api = Platform.isAndroid
        ? ffi.Api(await _getAndroidDynLib('libacter.so'))
        : ffi.Api.load();
    String logPath = await appCacheDir();
    FileSystemEntity? latestLogPath;

    try {
      // clear screenshots, and logs (but keep the latest one)
      final entities = Directory(logPath).list(
        recursive: false,
        followLinks: false,
      );
      await for (final entity in entities) {
        if (screenshotFileRegExp.hasMatch(entity.path)) {
          try {
            await entity.delete(); // remove old screenshots
          } catch (e) {
            print('Ignoring failure deleting $entity: $e');
          }
        }
        if (logFileRegExp.hasMatch(entity.path)) {
          if (latestLogPath == null) {
            latestLogPath = entity;
          } else {
            if (latestLogPath.path.compareTo(entity.path) < 0) {
              try {
                await latestLogPath.delete();
              } catch (e) {
                print('Ignoring failure deleting $latestLogPath: $e');
              }
              latestLogPath = entity;
            } else {
              try {
                await entity.delete();
              } catch (e) {
                print('Ignoring failure deleting $entity: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error reading $logPath for deleting : $e');
    }

    final logSettings = (await sharedPrefs()).getString(rustLogKey);
    try {
      print('log settings: ${logSettings ?? defaultLogSetting}');
      print('logs will be found in $logPath');
      api.initLogging(logPath, logSettings ?? defaultLogSetting);
    } catch (e) {
      developer.log(
        'Logging setup failed',
        level: 900, // warning
        error: e,
      );
    }

    final httpProxySettings =
        (await sharedPrefs()).getString(proxyKey) ?? defaultHttpProxy;

    try {
      if (httpProxySettings.isNotEmpty) {
        print('Setting http proxy to $httpProxySettings');
        api.setProxy(httpProxySettings);
      }
    } catch (e) {
      developer.log(
        'Proxy setup failed',
        level: 900, // warning
        error: e,
      );
    }
    final instance = ActerSdk._(api);
    if (latestLogPath != null) {
      instance._previousLogPath = latestLogPath.absolute.path;
      _log.info('Prior log file: ${instance._previousLogPath}');
    }
    return instance;
  }

  static Future<ActerSdk> get _unrestoredInstance async {
    if (_unrestoredInstanceCompl == null) {
      Completer<ActerSdk> completer = Completer();
      completer.complete(_unrestoredInstanceInner());
      _unrestoredInstanceCompl = completer;
    }
    return _unrestoredInstanceCompl!.future;
  }

  static Future<ActerSdk> _restoredInstanceInner() async {
    final instance = await _unrestoredInstance;
    await instance._restore();
    return instance;
  }

  static Future<ActerSdk> get _restoredInstance async {
    if (_instanceCompl == null) {
      Completer<ActerSdk> completer = Completer();
      completer.complete(_restoredInstanceInner());
      _instanceCompl = completer;
    }
    return _instanceCompl!.future;
  }

  static Future<ActerSdk> get instance async {
    return await _restoredInstance;
  }

  Future<ffi.Client> login(String username, String password) async {
    // To be removed when client management is implemented.
    for (final client in _clients) {
      if (client.userId().toString() == username) {
        return client;
      }
    }

    String appDocPath = await appDir();
    String appCachePath = await appCacheDir();
    final client = await _api.loginNewClient(
      appDocPath,
      appCachePath,
      username,
      password,
      defaultServerName,
      defaultServerUrl,
      userAgent,
    );
    if (_clients.length == 1 && _clients[0].isGuest()) {
      // we are replacing a guest account
      final client = _clients.removeAt(0);
      unawaited(
        client.logout().catchError((e) {
          _log.warning('Logout of Guest failed', e);
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
    _log.info('Remaining clients: ${_clients.length}');
    await _persistSessions();
    unawaited(
      client.logout().catchError((e) {
        _log.warning('Logout failed', e);
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
    String appCachePath = await appCacheDir();
    final client = await _api.registerWithToken(
      appDocPath,
      appCachePath,
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

  Future<bool> deactivateAndDestroyCurrentClient(String password) async {
    final client = currentClient;
    if (client == null) {
      return false;
    }

    final userId = client.userId().toString();

    // take it out of the loop
    if (_index >= 0 && _index < _clients.length) {
      _clients.removeAt(_index);
      _index = _index > 0 ? _index - 1 : 0;
    }
    try {
      if (!await client.deactivate(password)) {
        throw 'Deactivating the client failed';
      }
    } catch (e) {
      // reset the client locally
      _clients.add(client);
      _index = clients.length - 1;
      rethrow;
    }
    await _persistSessions();
    String appDocPath = await appDir();
    String appCachePath = await appCacheDir();

    return await _api.destroyLocalData(
      appDocPath,
      appCachePath,
      userId,
      defaultServerName,
    );
  }
}
