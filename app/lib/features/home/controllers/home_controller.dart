import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeStateProvider = StateNotifierProvider<HomeStateNotifier, bool>(
  (ref) => HomeStateNotifier(ref),
);

class HomeStateNotifier extends StateNotifier<bool> {
  final Ref ref;
  late ActerSdk sdk;
  late Client client;
  late SyncState syncState;
  HomeStateNotifier(this.ref) : super(false) {
    _loadUp();
  }

  void _loadUp() async {
    state = false;
    final asyncSdk = await ActerSdk.instance;
    PlatformDispatcher.instance.onError = (exception, stackTrace) {
      sdk.writeLog(exception.toString(), 'error');
      sdk.writeLog(stackTrace.toString(), 'error');
      return true; // make this error handled
    };
    sdk = asyncSdk;
    client = sdk.currentClient;
    syncState = client.startSync();
    state = true;
  }

  void refreshClient() {
    state = false;
    client = sdk.currentClient;
    syncState = client.startSync();
    state = true;
  }
}
