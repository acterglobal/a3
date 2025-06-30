import 'package:acter/features/activities/actions/key_storage_urgency_action.dart';
import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/features/datetime/providers/utc_now_provider.dart';
import 'package:riverpod/riverpod.dart';

final keyStorageUrgencyProvider = Provider<KeyStorageUrgency>((ref) {
  final timestamp = ref.watch(storedEncKeyTimestampProvider).valueOrNull;
  if (timestamp == null) return KeyStorageUrgency.normal;

  final now = ref.watch(utcNowProvider).millisecondsSinceEpoch ~/ 1000;
  final daysSinceStored = (now - timestamp) ~/ (24 * 60 * 60);

  if (daysSinceStored <= 3) return KeyStorageUrgency.normal;
  if (daysSinceStored <= 7) return KeyStorageUrgency.warning;
  return KeyStorageUrgency.critical;
});
