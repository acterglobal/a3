import 'dart:async';

import 'package:acter/common/providers/notifiers/sync_notifier.dart';
import 'package:acter/features/home/providers/notifiers/client_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class MockClientNotifier extends AsyncNotifier<ffi.Client?>
    with Mock
    implements ClientNotifier {
  final ffi.Client? client;

  MockClientNotifier({required this.client});

  @override
  FutureOr<ffi.Client?> build() => client;
}

class PendingUntilFoundMockClientNotifier extends AsyncNotifier<ffi.Client?>
    with Mock
    implements ClientNotifier {
  late Completer<ffi.Client> completer;

  PendingUntilFoundMockClientNotifier() {
    completer = Completer();
  }

  @override
  FutureOr<ffi.Client?> build() => completer.future;

  @override
  void setClient(ffi.Client? client) {
    completer.complete(client!);
  }
}

class MockSyncNotifier extends SyncNotifier {
  int restarted = 0;
  int clientSet = 0;
  ffi.Client? _client;

  @override
  set client(ffi.Client? value) {
    clientSet += 1;
    _client;
  }

  @override
  ffi.Client get client => _client!;

  @override
  void restartSync() {
    restarted += 1;
  }
}
