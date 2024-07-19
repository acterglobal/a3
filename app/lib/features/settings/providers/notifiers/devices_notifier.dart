import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::sessions::notifier');

class AsyncDevicesNotifier extends AsyncNotifier<List<DeviceRecord>> {
  Stream<String>? _newListener;
  StreamSubscription<String>? _newPoller;

  Stream<String>? _changedListener;
  StreamSubscription<String>? _changedPoller;

  @override
  Future<List<DeviceRecord>> build() async {
    final client = ref.watch(alwaysClientProvider);
    final manager = client.sessionManager();

    _newListener = client.deviceNewEventRx();
    _newPoller = _newListener?.listen(
      (devId) async {
        _log.info('--------------------------------- new devices detected');
        final sessions = (await manager.allSessions()).toList();
        state = AsyncValue.data(sessions);
      },
      onError: (e, stack) {},
      onDone: () {},
    );
    ref.onDispose(() => _newPoller?.cancel());

    _changedListener = client.deviceChangedEventRx();
    _changedPoller = _changedListener?.listen(
      (devId) async {
        _log.info('----------------------------- changed devices detected');
        final sessions = (await manager.allSessions()).toList();
        state = AsyncValue.data(sessions);
      },
      onError: (e, stack) {},
      onDone: () {},
    );
    ref.onDispose(() => _changedPoller?.cancel());

    final sessions = (await manager.allSessions()).toList();
    return sessions;
  }
}
