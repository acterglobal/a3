import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final backupManagerProvider = FutureProvider(
  (ref) => ref.watch(
    alwaysClientProvider.selectAsync((client) => client.backupManager()),
  ),
);

final storedEncKeyProvider = FutureProvider((ref) async {
  final manager = await ref.watch(backupManagerProvider.future);
  return manager.storedEncKey();
});

final enableEncrptionBackUpProvider = FutureProvider((ref) async {
  final manager = await ref.watch(backupManagerProvider.future);
  return manager.enable();
});

final resetEncrptionBackUpProvider = FutureProvider((ref) async {
  final manager = await ref.watch(backupManagerProvider.future);
  return manager.reset();
});

final disableEncrptionBackUpProvider = FutureProvider((ref) async {
  final manager = await ref.watch(backupManagerProvider.future);
  return manager.disable();
});
