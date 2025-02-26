import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart' show Client;
import 'package:riverpod/riverpod.dart';

class AlwaysClientNotifier extends AsyncNotifier<Client> {
  Completer<Client>? completer;
  late ProviderSubscription subscription;
  @override
  FutureOr<Client> build() async {
    final cpl = completer ??= Completer<Client>();
    subscription = ref.listen<AsyncValue<Client?>>(
      clientProvider,
      _updated,
      fireImmediately: true,
    );
    return cpl.future;
  }

  void _updated(AsyncValue<Client?>? old, AsyncValue<Client?> newV) {
    // set up the refresh
    final newClient = newV.valueOrNull;
    if (newClient != null) {
      final cmpl = completer;
      if (cmpl != null) {
        // we need to complete the previous future
        // which internally sets the new state
        cmpl.complete(newClient);
        completer = null;
      } else {
        // we need to update to the new value
        state = AsyncData(newClient);
      }
    } else if (old?.valueOrNull != null) {
      // we had a value previously, but now we don't, go back to endlessly
      // pending to stop all dependents in their track.
      state = AsyncValue.loading();
    }
  }
}
