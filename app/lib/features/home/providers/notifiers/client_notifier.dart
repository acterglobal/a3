import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::home::client_notifier');

class ClientNotifier extends StateNotifier<Client?> {
  ClientNotifier(Ref ref) : super(null) {
    _loadUp(ref);
  }

  Future<void> _loadUp(Ref ref) async {
    final asyncSdk = await ref.read(sdkProvider.future);
    PlatformDispatcher.instance.onError = (exception, stackTrace) {
      _log.severe('platform dispatch error', exception, stackTrace);
      return true; // make this error handled
    };
    state = asyncSdk.currentClient;
  }
}
