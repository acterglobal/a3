import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/features/backups/providers/notifiers/backup_state_notifier.dart';
import 'package:acter/features/backups/types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final backupStateProvider =
    NotifierProvider<BackupStateNotifier, BackupState>(() {
  return BackupStateNotifier();
});

final backupAreEnabledProvider = FutureProvider((ref) async {
  // ensure we reload if the backup state changed
  // ignore: unused_local_variable
  final currentState = ref.watch(backupStateProvider);
  final manager = ref.watch(backupManagerProvider);
  return await manager.areEnabled();
});

final backupExistsOnServerProvider = FutureProvider((ref) async {
  // ensure we reload if the backup state changed
  // ignore: unused_local_variable
  final currentState = ref.watch(backupStateProvider);
  final manager = ref.watch(backupManagerProvider);
  return await manager.existsOnServer();
});
