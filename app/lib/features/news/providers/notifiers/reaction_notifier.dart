import 'dart:async';

import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';

class AsyncNewsReactionsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<Reaction>, NewsEntry> {
  late Stream<void> _listener;
  late StreamSubscription<void> _sub;

  Future<List<Reaction>> _getReactionEntries() async {
    final manager = await arg.reactions();
    return (await manager.reactionEntries()).toList();
  }

  @override
  Future<List<Reaction>> build(NewsEntry arg) async {
    ref.onDispose(onDispose);
    final manager = await arg.reactions();
    _listener = manager.subscribeStream();
    _sub = _listener.listen(
      (e) async {
        debugPrint('seen update for news entry $arg');
        state = await AsyncValue.guard(() => _getReactionEntries());
      },
      onError: (e, stack) {
        debugPrint('stream errored: $e : $stack');
      },
      onDone: () {
        debugPrint('stream ended');
      },
    );
    return _getReactionEntries();
  }

  void onDispose() {
    debugPrint('disposing profile not for $arg');
    _sub.cancel();
  }
}
