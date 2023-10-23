import 'package:acter/common/notifications/notifications.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore_for_file: avoid_print
class ClientNotifier extends StateNotifier<Client?> {
  ClientNotifier(Ref ref) : super(null) {
    _loadUp(ref);
  }

  Future<void> _loadUp(Ref ref) async {
    final asyncSdk = await ref.watch(sdkProvider.future);
    PlatformDispatcher.instance.onError = (exception, stackTrace) {
      asyncSdk.writeLog(exception.toString(), 'error');
      asyncSdk.writeLog(stackTrace.toString(), 'error');
      return true; // make this error handled
    };
    final client = state = asyncSdk.currentClient;
    if (client != null) {
      await setupPushNotifications(client);
    }
  }
}
