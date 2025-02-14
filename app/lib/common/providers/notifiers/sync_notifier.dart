import 'dart:async';
import 'dart:math';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/models/sync_state/sync_state.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:riverpod/riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// ignore_for_file: avoid_print
class SyncNotifier extends Notifier<SyncState> {
  late ffi.Client client;

  late ffi.SyncState syncState;
  Stream<bool>? _syncListener;
  StreamSubscription<bool>? _syncPoller;
  Stream<String>? _errorListener;
  StreamSubscription<String>? _errorPoller;
  late ProviderSubscription _providerSubscription;
  Timer? _retryTimer;

  @override
  SyncState build() {
    _providerSubscription = ref.listen<AsyncValue<ffi.Client?>>(
      alwaysClientProvider,
      (AsyncValue<ffi.Client?>? oldVal, AsyncValue<ffi.Client?> newVal) {
        final newClient = newVal.valueOrNull;
        if (newClient == null) {
          // we don't care for not having a proper client yet
          return;
        }
        // on release we have a really weird behavior, where, if we schedule
        // any async call in rust too early, they just pend forever. this
        // hack unfortunately means we have two wait a bit but that means
        // we get past the threshold where it is okay to schedule...
        client = newClient;
        Future.delayed(
          const Duration(milliseconds: 1500),
          () async => await _restartSync(),
        );
      },
      fireImmediately: true,
    );
    ref.onDispose(() => _providerSubscription.close());
    return const SyncState(initialSync: true);
  }

  Future<void> _tickSyncState() async {
    await state.countDown.mapAsync(
      (countDown) async {
        if (countDown == 0) {
          await _restartSync();
        } else {
          // just count down.
          state = state.copyWith(countDown: countDown - 1);
        }
      },
      orElse: () async => await _restartSync(),
    );
  }

  Future<void> _restartSync() async {
    syncState = await client.startSync();

    // reset states
    _retryTimer?.cancel();
    _retryTimer = null;
    _syncPoller?.cancel();
    _errorPoller?.cancel();

    _syncListener = syncState.firstSyncedRx(); // keep it resident in memory
    _syncPoller = _syncListener?.listen((synced) {
      if (synced) {
        state = const SyncState(initialSync: false);
      }
    });
    ref.onDispose(() => _syncPoller?.cancel());

    _errorListener = syncState.syncErrorRx(); // keep it resident in memory
    _errorPoller = _errorListener?.listen((msg) {
      Sentry.captureMessage('Sync failure: $msg', level: SentryLevel.error);
      if (msg == 'SoftLogout' || msg == 'Unauthorized') {
        // regular logout, we do nothing here
        state = SyncState(initialSync: false, errorMsg: msg);
      } else {
        final retry = min(
          state.nextRetry.map((nextRetry) => nextRetry * 2) ?? 5,
          300,
        ); // we double this to a max of 5min.
        state = state.copyWith(
          initialSync: false,
          errorMsg: msg,
          countDown: retry,
          nextRetry: retry,
        );
        _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
          await _tickSyncState();
        });
        // custom errors, means we will start the retry loop
      }
    });
    ref.onDispose(() => _errorPoller?.cancel());
  }
}
