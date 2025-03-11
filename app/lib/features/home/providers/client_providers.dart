import 'package:acter/common/models/sync_state/sync_state.dart';
import 'package:acter/features/home/providers/notifiers/always_client_notifier.dart';
import 'package:acter/features/home/providers/notifiers/client_notifier.dart';
import 'package:acter/common/providers/notifiers/sync_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart' show Client;
import 'package:riverpod/riverpod.dart';

final clientProvider = AsyncNotifierProvider<ClientNotifier, Client?>(
  () => ClientNotifier(),
);

final alwaysClientProvider =
    AsyncNotifierProvider<AlwaysClientNotifier, Client>(
      () => AlwaysClientNotifier(),
    );

final syncStateProvider = NotifierProvider<SyncNotifier, SyncState>(
  () => SyncNotifier(),
);

final isSyncingStateProvider = StateProvider<bool>((ref) {
  return ref.watch(syncStateProvider).initialSync;
});
