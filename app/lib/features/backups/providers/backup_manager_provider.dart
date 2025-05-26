import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final backupManagerProvider = FutureProvider(
  (ref) => ref.watch(
    alwaysClientProvider.selectAsync((client) => client.backupManager()),
  ),
);

final enableEncrptionBackUpProvider = FutureProvider((ref) async {
  final manager = await ref.watch(backupManagerProvider.future);
  return manager.enable();
});

final storedEncKeyProvider = FutureProvider((ref) async {
  final manager = await ref.watch(backupManagerProvider.future);
  return manager.storedEncKey();
});

final storedEncKeyTimestampProvider = FutureProvider((ref) async {
  final manager = await ref.watch(backupManagerProvider.future);
  return manager.storedEncKeyWhen();
});