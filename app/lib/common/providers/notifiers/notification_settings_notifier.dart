import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';

// ignore_for_file: unused_field

class AsyncNotificationSettingsNotifier
    extends AsyncNotifier<NotificationSettings> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _sub;

  @override
  Future<NotificationSettings> build() async {
    final client = ref.watch(alwaysClientProvider);
    final settings = await client.notificationSettings();
    ref.onDispose(onDispose);
    _listener = settings.changesStream();
    _sub = _listener.listen(
      (e) async {
        // reset the state of this to trigger the notification
        // cascade
        state = AsyncValue.data(settings);
      },
      onError: (e, stack) {
        debugPrint('stream errored: $e : $stack');
      },
      onDone: () {
        debugPrint('stream ended');
      },
    );
    return settings;
  }

  void onDispose() {
    _sub.cancel();
  }
}
