import 'package:acter/common/models/sync_state/sync_state.dart';
import 'package:acter/features/home/providers/notifiers/client_notifier.dart';
import 'package:acter/common/providers/notifiers/sync_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart' show Client;
import 'package:riverpod/riverpod.dart';

class NoClientException implements Exception {
  NoClientException();
}

final clientProvider =
    AsyncNotifierProvider<ClientNotifier, Client?>(() => ClientNotifier());

final alwaysClientProvider = FutureProvider((ref) async {
  final client = await ref.watch(clientProvider.future);
  if (client == null) {
    throw NoClientException();
  }
  return client;
});

final syncStateProvider =
    NotifierProvider<SyncNotifier, SyncState>(() => SyncNotifier());

final isSyncingStateProvider = StateProvider<bool>((ref) {
  return ref.watch(syncStateProvider).initialSync;
});
