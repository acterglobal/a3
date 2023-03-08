import 'package:effektio/features/home/repositories/client_repository.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeStateProvider = StateNotifierProvider<HomeStateNotifier, bool>(
  (ref) => HomeStateNotifier(ref),
);

class HomeStateNotifier extends StateNotifier<bool> {
  final Ref ref;
  late EffektioSdk sdk;
  late Client client;
  late SyncState syncState;
  HomeStateNotifier(this.ref) : super(false) {
    _loadUp();
}

  void _loadUp() async {
    state = false;
    final asyncSdk = await EffektioSdk.instance;
    sdk = asyncSdk;
    client = sdk.currentClient;
    syncState = client.startSync();
    state = true;
  }

  void refreshClient() {
    state = false;
    client = sdk.currentClient;
    ref.read(clientRepositoryProvider.notifier).state =
        ClientRepository(client: client);
    state = true;
  }
}
