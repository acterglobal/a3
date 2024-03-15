import 'dart:async';

import 'package:acter/features/backups/providers/backup_manager.dart';
import 'package:acter/features/backups/types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackupStateNotifier extends Notifier<BackupState> {
  late Stream<String> _listener;
  // ignore: unused_field
  late StreamSubscription<String> _poller;

  @override
  BackupState build() {
    // Load initial todo list from the remote repository
    final backup = ref.watch(backUpManagerProvider);
    _listener = backup.stateStream(); // keep it resident in memory
    _poller = _listener.listen((element) async {
      state = stringToState(element);
    });
    ref.onDispose(() => _poller.cancel());
    return stringToState(backup.stateStr());
  }
}
