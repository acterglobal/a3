import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::common::notification_settings');

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
        _log.severe('stream errored', e, stack);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    return settings;
  }

  void onDispose() {
    _sub.cancel();
  }
}
