import 'package:acter/common/providers/notifiers/client_pref_notifier.dart';
import 'package:acter/features/backups/providers/notifiers/backup_state_notifier.dart';
import 'package:acter/features/backups/types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final backupStateProvider =
    NotifierProvider<RecoveryStateNotifier, RecoveryState>(() {
      return RecoveryStateNotifier();
    });

final backupAreEnabledProvider = FutureProvider((ref) async {
  return ref.watch(backupStateProvider) == RecoveryState.enabled;
});

final backupNeedRecoveryProvider = FutureProvider((ref) async {
  return ref.watch(backupStateProvider) == RecoveryState.incomplete;
});

final hasProvidedKeyProvider =
    AsyncNotifierProvider<AsyncPrefNotifier<bool>, bool>(
      () => AsyncPrefNotifier<bool>('has_provided_backup_key', false),
    );
