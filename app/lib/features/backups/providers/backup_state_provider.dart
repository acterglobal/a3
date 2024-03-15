import 'package:acter/features/backups/providers/notifiers/backup_state_notifier.dart';
import 'package:acter/features/backups/types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final backupStateProvider =
    NotifierProvider<BackupStateNotifier, BackupState>(() {
  return BackupStateNotifier();
});
