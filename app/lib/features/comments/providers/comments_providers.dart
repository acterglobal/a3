import 'dart:async';

import 'package:acter/features/comments/types.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::comments::manager');

final commentsManagerProvider = AsyncNotifierProvider.autoDispose.family<
    AsyncCommentsManagerNotifier, CommentsManager, CommentsManagerProvider>(
  () => AsyncCommentsManagerNotifier(),
);

class AsyncCommentsManagerNotifier extends AutoDisposeFamilyAsyncNotifier<
    CommentsManager, CommentsManagerProvider> {
  late Stream<bool> _listener;
  late StreamSubscription<void> _poller;

  @override
  FutureOr<CommentsManager> build(CommentsManagerProvider arg) async {
    final manager = await arg.getManager();
    _listener = manager.subscribeStream(); // keep it resident in memory
    _poller = _listener.listen(
      (data) async {
        // reset
        state = AsyncValue.data(await manager.reload());
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
  final commentList = (await manager.comments()).toList();
  commentList.sort(
    (a, b) => b.originServerTs().compareTo(a.originServerTs()),
  );
  return commentList;
});

final newsCommentsCountProvider = FutureProvider.family
    .autoDispose<int, CommentsManagerProvider>((ref, managerProvider) async {
  final commentManager =
      await ref.watch(commentsManagerProvider(managerProvider).future);
  final commentList =
      await ref.watch(commentsListProvider(commentManager).future);
  return commentList.length;
});
