import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::settings::devices');

class AsyncDevicesNotifier extends AsyncNotifier<List<DeviceRecord>> {
  Stream<DeviceEvent>? _listener;
  StreamSubscription<DeviceEvent>? _poller;

  @override
  Future<List<DeviceRecord>> build() async {
    final client = ref.watch(alwaysClientProvider);
    final manager = client.sessionManager();

    _listener = client.deviceEventRx();
    _poller = _listener?.listen(
      (evt) async {
        final sessions = (await manager.allSessions()).toList();
        state = AsyncValue.data(sessions);
      },
      onError: (e, s) {
        _log.severe('stream errored', e, s);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    ref.onDispose(() => _poller?.cancel());

    final sessions = (await manager.allSessions()).toList();
    return sessions;
  }
}
