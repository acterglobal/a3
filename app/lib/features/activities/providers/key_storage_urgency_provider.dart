import 'package:acter/features/activities/actions/key_storage_urgency_action.dart';
import 'package:acter/features/datetime/providers/utc_now_provider.dart';
import 'package:riverpod/riverpod.dart';

final keyStorageUrgencyProvider = Provider.family<KeyStorageUrgency, int>((ref, timestamp) {
  if (timestamp == 0) return KeyStorageUrgency.normal;
  
  final now = ref.watch(utcNowProvider).millisecondsSinceEpoch ~/ 1000;
  final daysSinceStored = (now - timestamp) ~/ (24 * 60 * 60);

  if (daysSinceStored <= 3) return KeyStorageUrgency.normal;
  if (daysSinceStored <= 7) return KeyStorageUrgency.warning;
  return KeyStorageUrgency.critical;
});