import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncPinsNotifier extends AutoDisposeAsyncNotifier<List<ActerPin>> {
  late Stream<void> _listener;

  late StreamSubscription<void> _poller;

  Future<List<ActerPin>> _getPins() async {
    final client = ref.read(alwaysClientProvider);
    return (await client.pins()).toList(); // this might throw internally
  }

  @override
  Future<List<ActerPin>> build() async {
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream('pins'); // stay up to date
    _poller = _listener.listen((e) async {
      state = await AsyncValue.guard(() => _getPins());
    });
    ref.onDispose(() => _poller.cancel());
    return _getPins();
  }
}

class AsyncPinNotifier
    extends AutoDisposeFamilyAsyncNotifier<ActerPin, String> {
  late Stream<void> _listener;

  late StreamSubscription<void> _poller;

  Future<ActerPin> _getPin() async {
    final client = ref.read(alwaysClientProvider);
    return await client.waitForPin(arg, null);
  }

  @override
  Future<ActerPin> build(String arg) async {
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream(arg);
    _poller = _listener.listen((e) async {
      debugPrint('---------------------- new pin subscribe recieved');
      state = await AsyncValue.guard(() => _getPin());
    }); // stay up to date
    ref.onDispose(() => _poller.cancel());
    return _getPin();
  }
}

class AsyncSpacePinsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<ActerPin>, Space> {
  late Stream<void> _listener;

  late StreamSubscription<void> _poller;

  Future<List<ActerPin>> _getPins() async {
    return (await arg.pins()).toList(); // this might throw internally
  }

  @override
  Future<List<ActerPin>> build(Space arg) async {
    final client = ref.watch(alwaysClientProvider);
    final spaceId = arg.getRoomId();
    _listener = client.subscribeStream('$spaceId::pins'); // stay up to date
    _poller = _listener.listen((e) async {
      debugPrint('---------------------- new pin subscribe recieved');
      state = await AsyncValue.guard(() => _getPins());
    });
    ref.onDispose(() => _poller.cancel());
    return _getPins();
  }
}
