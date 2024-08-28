import 'dart:async';

import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/features/backups/types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::backups::backup_state');

class RecoveryStateNotifier extends Notifier<RecoveryState> {
  late Stream<String> _listener;
  late StreamSubscription<String> _poller;

  @override
  RecoveryState build() {
    // Load initial todo list from the remote repository
    final backup = ref.watch(backupManagerProvider);
    _listener = backup.stateStream(); // keep it resident in memory
    _poller = _listener.listen(
      (data) async {
        state = stringToState(data);
      },
      onError: (e, s) {
        _log.severe('stream errored', e, s);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return stringToState(backup.stateStr());
  }
}
