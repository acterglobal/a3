import 'dart:async';
import 'dart:math';

import 'package:acter/common/models/sync_state/sync_state.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore_for_file: avoid_print
class SyncNotifier extends StateNotifier<SyncState> {
  final ffi.Client client;
  final Ref ref;

  late ffi.SyncState syncState;
  late Stream<bool> syncListener;
  late StreamSubscription<bool> syncPoller;
  late Stream<String> errorListener;
  late StreamSubscription<String> errorPoller;
  Timer? retryTimer;

  SyncNotifier(this.client, this.ref)
      : super(const SyncState(initialSync: true)) {
    _startSync(ref);
  }

  Future<void> _startSync(Ref ref) async {
    // on release we have a really weird behavior, where, if we schedule
    // any async call in rust too early, they just pend forever. this
    // hack unfortunately means we have two wait a bit but that means
    // we get past the threshold where it is okay to schedule...
    await Future.delayed(const Duration(milliseconds: 1500));
    _restartSync();
  }

  void _tickSyncState() {
    if (state.countDown == null || state.countDown == 0) {
      _restartSync();
    } else {
      // just count down.
      state = state.copyWith(
        countDown: (state.countDown ?? 0) > 0 ? (state.countDown! - 1) : null,
      );
    }
  }

  Future<void> _restartSync() async {
    syncState = client.startSync();
    if (retryTimer != null) {
      retryTimer!.cancel();
      retryTimer = null;
    }

    syncListener = syncState.firstSyncedRx(); // keep it resident in memory
    syncPoller = syncListener.listen((synced) {
      if (synced) {
        if (mounted) {
          state = const SyncState(
            initialSync: false,
          );
        }
        ref.invalidate(spacesProvider);
      }
    });
    ref.onDispose(() => syncPoller.cancel());

    errorListener = syncState.syncErrorRx(); // keep it resident in memory
    errorPoller = errorListener.listen((msg) {
      if (mounted) {
        if (msg == 'SoftLogout' || msg == 'Unauthorized') {
          // regular logout, we do nothing here
          state = SyncState(initialSync: false, errorMsg: msg);
        } else {
          final retry = min(
            (state.nextRetry == null ? 5 : state.nextRetry! * 2),
            300,
          ); // we double this to a max of 5min.
          state = state.copyWith(
            initialSync: false,
            errorMsg: msg,
            countDown: retry,
            nextRetry: retry,
          );
          retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            _tickSyncState();
          });
          // custom errors, means we will start the retry loop
        }
      }
    });
    ref.onDispose(() => errorPoller.cancel());
  }
}
