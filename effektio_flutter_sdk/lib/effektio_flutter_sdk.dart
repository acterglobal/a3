library effektio;

import 'dart:core';
import 'dart:io';
import "package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart";
import 'package:path_provider/path_provider.dart';

class EffektioSdk {
  static EffektioSdk? _instance;
  late final Api _api;
  final List<Client> _clients = [];

  EffektioSdk._(this._api);

  Future<bool> restore() async {
    return false;
  }

  static Future<EffektioSdk> get instance async {
    if (_instance == null) {
      final api = Api.load();
      api.initLogging("warn");
      _instance = EffektioSdk._(api);
    }
    return _instance!;
  }

  Future<Client> login(String username, String password) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    final client = await _api.loginNewClient(username, password, appDocPath);
    _clients.add(client);
    return client;
  }

  List<Client> get clients {
    return _clients;
  }
}
