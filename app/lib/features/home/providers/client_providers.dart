import 'package:acter/common/models/sync_state/sync_state.dart';
import 'package:acter/features/cross_signing/cross_signing.dart';
import 'package:acter/features/home/providers/notifiers/client_notifier.dart';
import 'package:acter/common/providers/notifiers/sync_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart' show Client;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NoClientException implements Exception {
  NoClientException();
}

final clientProvider = StateNotifierProvider<ClientNotifier, Client?>((ref) {
  return ClientNotifier(ref);
});

final alwaysClientProvider = StateProvider((ref) {
  final client = ref.watch(clientProvider);
  if (client == null) {
    throw NoClientException();
  }
  return client;
});

final syncStateProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final client = ref.watch(alwaysClientProvider);
  final _ = CrossSigning(client: client);
  return SyncNotifier(client, ref);
});

final isSyncingStateProvider = StateProvider<bool>((ref) {
  return ref.watch(syncStateProvider).initialSync;
});
