import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart' show Client;
import 'package:riverpod/riverpod.dart';

class AlwaysClientNotifier extends AsyncNotifier<Client> {
  Completer<Client>? completer;
  late ProviderSubscription subscription;
  @override
  FutureOr<Client> build() async {
    subscription = ref.listen<AsyncValue<Client?>>(clientProvider, _updated);
    final client = await ref.read(clientProvider.future);
    if (client != null) {
      return client;
    }

    final cpl = completer ??= Completer<Client>();
    return cpl.future;
  }

  void _updated(AsyncValue<Client?>? old, AsyncValue<Client?> newV) {
    // set up the refresh
    final newClient = newV.valueOrNull;
    if (newClient != null) {
      state = AsyncData(newClient);
      // and inform any pending completers
      completer?.complete(newClient);
      completer = null;
    } else {
      state = AsyncValue.loading();
    }
  }
}
