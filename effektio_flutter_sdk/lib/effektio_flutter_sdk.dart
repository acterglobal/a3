library effektio;

import 'dart:core';
import 'dart:io';
import "package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart";
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EffektioSdk {
  static EffektioSdk? _instance;
  late final Api _api;
  final List<Client> _clients = [];

  EffektioSdk._(this._api);

  Future<void> _persistSessions() async {
    List<String> sessions = [];
    // FIXME: parallel?!?
    for (var c in _clients) {
      String token = await c.restoreToken();
      sessions.add(token);
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList("sessions", sessions);
  }

  Future<void> _restore() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> sessions = (prefs.getStringList("sessions") ?? []);
    // TODO: parallel?!?
    for (var token in sessions) {
      Client client = await _api.loginWithToken(appDocPath, token);
      clients.add(client);
    }
    print("Restored $_clients");
  }

  static Future<EffektioSdk> get instance async {
    if (_instance == null) {
      final api = Api.load();
      api.initLogging("warn");
      _instance = EffektioSdk._(api);
      await _instance!._restore();
    }
    return _instance!;
  }

  Future<Client> login(String username, String password) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    final client = await _api.loginNewClient(appDocPath, username, password);
    _clients.add(client);
    await _persistSessions();
    return client;
  }

  List<Client> get clients {
    return _clients;
  }
}
