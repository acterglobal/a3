import 'dart:async';
import 'dart:math';

import 'package:acter/common/models/sync_state/sync_state.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:riverpod/riverpod.dart';

// ignore_for_file: avoid_print
class SyncNotifier extends StateNotifier<SyncState> {
  final ffi.Client client;
  final Ref ref;

  late ffi.SyncState syncState;
  late Stream<bool> _syncListener;
  late StreamSubscription<bool> _syncPoller;
  late Stream<String> _errorListener;
  late StreamSubscription<String> _errorPoller;
  Timer? _retryTimer;

  SyncNotifier(this.client, this.ref)
      : super(const SyncState(initialSync: true)) {
    _startSync(ref);
  }

  void _startSync(Ref ref) {
    // on release we have a really weird behavior, where, if we schedule
    // any async call in rust too early, they just pend forever. this
    // hack unfortunately means we have two wait a bit but that means
    // we get past the threshold where it is okay to schedule...
    Future.delayed(const Duration(milliseconds: 1500), () => _restartSync());
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

  void _restartSync() {
    syncState = client.startSync();
    if (_retryTimer != null) {
      _retryTimer!.cancel();
      _retryTimer = null;
    }

    _syncListener = syncState.firstSyncedRx(); // keep it resident in memory
    _syncPoller = _syncListener.listen((synced) {
      if (synced) {
        if (mounted) {
          state = const SyncState(initialSync: false);
        }
        ref.invalidate(spacesProvider);
      }
    });
    ref.onDispose(() => _syncPoller.cancel());

    _errorListener = syncState.syncErrorRx(); // keep it resident in memory
    _errorPoller = _errorListener.listen((msg) {
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
          _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            _tickSyncState();
          });
          // custom errors, means we will start the retry loop
        }
      }
    });
    ref.onDispose(() => _errorPoller.cancel());
  }
}
