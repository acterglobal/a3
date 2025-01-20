import 'dart:async';

import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/features/backups/types.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::backups::backup_state');

class RecoveryStateNotifier extends Notifier<RecoveryState> {
  late Stream<String> _listener;
  StreamSubscription<String>? _poller;
  late ProviderSubscription _providerSubscription;

  @override
  RecoveryState build() {
    _providerSubscription =
        ref.listen<AsyncValue<BackupManager?>>(backupManagerProvider, (
      AsyncValue<BackupManager?>? oldVal,
      AsyncValue<BackupManager?> newVal,
    ) {
      final next = newVal.valueOrNull;
      if (next == null) {
        // we don't care for not having a proper client yet
        return;
      }
      _reset(next);
    });
    ref.onDispose(() => _providerSubscription.close());
    return RecoveryState.unknown;
  }

  void _reset(BackupManager backup) {
    _listener = backup.stateStream(); // keep it resident in memory
    _poller?.cancel();
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
    ref.onDispose(() => _poller?.cancel());
  }
}
