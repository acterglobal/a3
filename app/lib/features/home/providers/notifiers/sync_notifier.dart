import 'dart:async';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocalSyncState {
  final bool syncing;
  final String? errorMsg;

  const LocalSyncState(this.syncing, {this.errorMsg});
}

// ignore_for_file: avoid_print
class SyncNotifier extends StateNotifier<LocalSyncState> {
  late SyncState syncState;
  late Stream<bool> syncListener;
  late StreamSubscription<bool> syncPoller;
  late Stream<String>? notifications;
  late Stream<String> errorListener;
  late StreamSubscription<String> errorPoller;
  late Ref ref;

  SyncNotifier(Client? client, Ref ref) : super(const LocalSyncState(true)) {
    if (client != null) {
      startSync(client, ref);
    } else {
      state = const LocalSyncState(false, errorMsg: 'No active client');
    }
  }

  Future<void> startSync(Client client, Ref ref) async {
    // on release we have a really weird behavior, where, if we schedule
    // any async call in rust too early, they just pend forever. this
    // hack unfortunately means we have two wait a bit but that means
    // we get past the threshold where it is okay to schedule...
    await Future.delayed(const Duration(milliseconds: 1500));
    syncState = client.startSync();

    syncListener = syncState.firstSyncedRx(); // keep it resident in memory
    syncPoller = syncListener.listen((synced) {
      if (synced) {
        if (mounted) {
          state = const LocalSyncState(false);
        }
        ref.invalidate(spacesProvider);
      }
    });
    ref.onDispose(() => syncPoller.cancel());

    errorListener = syncState.syncErrorRx(); // keep it resident in memory
    errorPoller = errorListener.listen((msg) {
      if (mounted) {
        state = LocalSyncState(false, errorMsg: msg);
      }
      ref.invalidate(spacesProvider);
    });
    ref.onDispose(() => errorPoller.cancel());
  }
}
