import 'dart:core';
import 'dart:io';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
export './effektio_flutter_sdk_ffi.dart' show Client, Room, News, Faq;

// class EffektioClient extends ChangeNotifier {
//   final Client client;
//   EffektioClient(this.client);
// }

class EffektioSdk {
  static EffektioSdk? _instance;
  late final Api _api;
  final int _index = 0;
  final List<Client> _clients = [];

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
    // TODO: parallel?!?
    bool loggedIn = false;
    for (var token in sessions) {
      Client client = await _api.loginWithToken(appDocPath, token);
      clients.add(client);
      loggedIn = await client.loggedIn();
    }

    if (_clients.isEmpty) {
      Client client =
          await _api.guestClient(appDocPath, 'https://matrix.effektio.org');
      clients.add(client);
      loggedIn = await client.loggedIn();
      await _persistSessions();
    }
    debugPrint('Restored $_clients: $loggedIn');
  }

  Future<Client> get currentClient async {
    return _clients[_index];
  }

  static Future<EffektioSdk> get instance async {
    if (_instance == null) {
      final api = Api.load();
      api.initLogging('warn');
      _instance = EffektioSdk._(api);
      await _instance!._restore();
    }
    return _instance!;
  }

  Future<Client> login(String username, String password) async {
    // To be removed when client management is implemented.
    for (final client in _clients) {
      if (await client.userId() == username) {
        return client;
      }
    }

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    final client = await _api.loginNewClient(appDocPath, username, password);
    if (_clients.length == 1 && _clients[0].isGuest()) {
      // we are replacing a guest account
      _clients.removeAt(0);
    }
    _clients.add(client);
    await _persistSessions();
    return client;
  }

  List<Client> get clients {
    return _clients;
  }
}
