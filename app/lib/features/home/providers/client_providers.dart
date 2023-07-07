import 'package:acter/features/home/providers/notifiers/client_notifier.dart';
import 'package:acter/features/home/providers/notifiers/sync_state.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart' show Client;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clientProvider = StateNotifierProvider<ClientNotifier, Client?>(
  (ref) => ClientNotifier(ref),
);

final syncStateProvider = StateNotifierProvider<SyncNotifier, bool>((ref) {
  final client = ref.watch(clientProvider);
  return SyncNotifier(client!, ref);
});
