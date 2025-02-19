import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show NotificationSettings;
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::common::notification_settings_notifier');

class AsyncNotificationSettingsNotifier
    extends AsyncNotifier<NotificationSettings> {
  // ignore: unused_field
  Stream<bool>? _listener;
  StreamSubscription<bool>? _poller;

  @override
  Future<NotificationSettings> build() async {
    ref.onDispose(() => _poller?.cancel());
    return await reset();
  }

  Future<NotificationSettings> reset() async {
    _poller?.cancel();
    final client = await ref.watch(alwaysClientProvider.future);
    final settings = await client.notificationSettings();
    final listener = _listener = settings.changesStream();
    _poller = listener.listen(
      (data) async {
        // reset the state of this to trigger the notification
        // cascade
        state = AsyncValue.data(await reset());
      },
      onError: (e, s) {
        _log.severe('stream errored', e, s);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    return settings;
  }
}
