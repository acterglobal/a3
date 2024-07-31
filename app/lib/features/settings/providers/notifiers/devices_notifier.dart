import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::settings::devices');

class AsyncDevicesNotifier extends AsyncNotifier<List<DeviceRecord>> {
  Stream<DeviceNewEvent>? _newListener;
  StreamSubscription<DeviceNewEvent>? _newPoller;

  Stream<DeviceChangedEvent>? _changedListener;
  StreamSubscription<DeviceChangedEvent>? _changedPoller;

  @override
  Future<List<DeviceRecord>> build() async {
    final client = ref.watch(alwaysClientProvider);
    final manager = client.sessionManager();

    _newListener = client.deviceNewEventRx();
    _newPoller = _newListener?.listen(
      (evt) async {
        final sessions = (await manager.allSessions()).toList();
        state = AsyncValue.data(sessions);
      },
      onError: (e, stack) {
        _log.severe('stream errored', e, stack);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    ref.onDispose(() => _newPoller?.cancel());

    _changedListener = client.deviceChangedEventRx();
    _changedPoller = _changedListener?.listen(
      (evt) async {
        final sessions = (await manager.allSessions()).toList();
        state = AsyncValue.data(sessions);
      },
      onError: (e, stack) {
        _log.severe('stream errored', e, stack);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    ref.onDispose(() => _changedPoller?.cancel());

    final sessions = (await manager.allSessions()).toList();
    return sessions;
  }
}
