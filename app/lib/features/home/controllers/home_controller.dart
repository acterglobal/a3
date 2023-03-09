import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeStateProvider = StateNotifierProvider<HomeStateNotifier, Client?>(
  (ref) => HomeStateNotifier(ref),
);

class HomeStateNotifier extends StateNotifier<Client?> {
  final Ref ref;
  late EffektioSdk sdk;
  late SyncState syncState;
  HomeStateNotifier(this.ref) : super(null) {
    _loadUp();
  }

  void _loadUp() async {
    final asyncSdk = await EffektioSdk.instance;
    PlatformDispatcher.instance.onError = (exception, stackTrace) {
      asyncSdk.writeLog(exception.toString(), 'error');
      asyncSdk.writeLog(stackTrace.toString(), 'error');
      return true; // make this error handled
    };
    sdk = asyncSdk;
    state = sdk.currentClient;
    syncState = state!.startSync();
  }
}
