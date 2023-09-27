import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';

// ignore_for_file: unused_field

class AsyncMaybeRoomNotifier extends FamilyAsyncNotifier<Room?, String> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _sub;

  Future<Room?> _getRoom() async {
    final client = ref.read(clientProvider)!;
    return await client.room(arg);
  }

  @override
  Future<Room?> build(String arg) async {
    final client = ref.watch(clientProvider)!;
    ref.onDispose(onDispose);
    _listener = client.subscribeStream(arg);
    _sub = _listener.listen(
      (e) async {
        debugPrint('seen update for room $arg');

        state = await AsyncValue.guard(() => _getRoom());
      },
      onError: (e, stack) {
        debugPrint('stream errored: $e : $stack');
      },
      onDone: () {
        debugPrint('stream ended');
      },
    );
    return _getRoom();
  }

  void onDispose() {
    debugPrint('disposing profile not for $arg');
    _sub.cancel();
  }
}
