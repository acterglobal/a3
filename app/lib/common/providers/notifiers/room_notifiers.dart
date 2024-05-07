import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::room');

class AsyncMaybeRoomNotifier extends FamilyAsyncNotifier<Room?, String> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  Future<Room?> _getRoom() async {
    final client = ref.read(alwaysClientProvider);
    try {
      return await client.room(arg);
    } catch (e, stack) {
      _log.severe('room not found', e, stack);
      return null;
    }
  }

  @override
  Future<Room?> build(String arg) async {
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream(arg); // keep it resident in memory
    _poller = _listener.listen(
      (e) async {
        _log.info('seen update for room $arg');
        state = await AsyncValue.guard(_getRoom);
      },
      onError: (e, stack) {
        _log.severe('stream errored', e, stack);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return await _getRoom();
  }
}
