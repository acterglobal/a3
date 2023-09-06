import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:acter/common/models/profile_data.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';

// ignore_for_file: unused_field

class AsyncConvoNotifier extends FamilyAsyncNotifier<Convo?, Convo> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _sub;

  @override
  Future<Convo> build(Convo arg) async {
    final convo = arg;
    final convoId = convo.getRoomId().toString();
    final client = ref.watch(clientProvider)!;
    ref.onDispose(onDispose);
    _listener = client.subscribeStream(convoId);
    _sub = _listener.listen(
      (e) async {
        state = await AsyncValue.guard(() => client.convo(convoId));
      },
      onError: (e, stack) {
        debugPrint('stream errored: $e : $stack');
      },
      onDone: () {
        debugPrint('stream ended');
      },
    );
    return convo;
  }

  void onDispose() {
    debugPrint('disposing profile not for $arg');
    _sub.cancel();
  }
}
