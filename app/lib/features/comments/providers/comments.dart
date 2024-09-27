import 'dart:async';

import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Comment, CommentsManager;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::comments::manager');

final commentsManagerProvider = AsyncNotifierProvider.autoDispose.family<
    AsyncCommentsManagerNotifier, CommentsManager, Future<CommentsManager>>(
  () => AsyncCommentsManagerNotifier(),
);

class AsyncCommentsManagerNotifier extends AutoDisposeFamilyAsyncNotifier<
    CommentsManager, Future<CommentsManager>> {
  late Stream<bool> _listener;
  late StreamSubscription<void> _poller;

  @override
  FutureOr<CommentsManager> build(Future<CommentsManager> arg) async {
    final manager = await arg;
    _listener = manager.subscribeStream(); // keep it resident in memory
    _poller = _listener.listen(
      (data) async {
        // reset
        state = await AsyncValue.guard(() async => await manager.reload());
      },
      onError: (e, s) {
        _log.severe('msg stream errored', e, s);
      },
      onDone: () {
        _log.info('msg stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return manager;
  }
}

final commentsListProvider = FutureProvider.family
    .autoDispose<List<Comment>, CommentsManager>((ref, manager) async {
  return (await manager.comments()).toList();
});
