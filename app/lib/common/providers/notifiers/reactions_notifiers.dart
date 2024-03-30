import 'dart:async';

import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::common::reactions');

class ReactionManagerNotifier
    extends FamilyNotifier<ReactionManager, ReactionManager> {
  late Stream<void> _listener;
  late StreamSubscription<void> _poller;

  @override
  ReactionManager build(ReactionManager arg) {
    _listener = arg.subscribeStream(); // keep it resident in memory
    _poller = _listener.listen(
      (e) async {
        _log.info('attempting to reload');
        final newManager = await arg.reload();
        _log.info('manager updated. likes: ${newManager.likesCount()}');
        state = newManager;
      },
      onError: (e, stack) {
        _log.severe('stream errored.', e, stack);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return arg;
  }
}
