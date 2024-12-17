import 'dart:async';

import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show ReadReceiptsManager;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::read_receipts::manager');

final readReceiptsManagerProvider = AsyncNotifierProvider.autoDispose.family<
    AsyncReadReceiptsManagerNotifier,
    ReadReceiptsManager,
    Future<ReadReceiptsManager>>(
  () => AsyncReadReceiptsManagerNotifier(),
);

class AsyncReadReceiptsManagerNotifier extends AutoDisposeFamilyAsyncNotifier<
    ReadReceiptsManager, Future<ReadReceiptsManager>> {
  late Stream<bool> _listener;
  late StreamSubscription<void> _poller;

  @override
  FutureOr<ReadReceiptsManager> build(Future<ReadReceiptsManager> arg) async {
    final manager = await arg;
    _listener = manager.subscribeStream(); // keep it resident in memory
    _poller = _listener.listen(
      (data) async {
        // reset
        state = AsyncData(await manager.reload());
      },
      onError: (e, s) {
        _log.severe('read receipt reload stream errored', e, s);
      },
      onDone: () {
        _log.info('read receipt reload stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return manager;
  }
}

final hasReadProvider = Provider.family.autoDispose<bool, ReadReceiptsManager>(
  (ref, manager) => manager.readByMe(),
);

final readCountProvider = Provider.family.autoDispose<int, ReadReceiptsManager>(
  (ref, manager) => manager.readCount(),
);
