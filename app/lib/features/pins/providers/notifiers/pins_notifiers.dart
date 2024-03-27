import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

class AsyncPinsNotifier extends AutoDisposeAsyncNotifier<List<ActerPin>> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  Future<List<ActerPin>> _getPins() async {
    final client = ref.read(alwaysClientProvider);
    return (await client.pins()).toList(); // this might throw internally
  }

  @override
  Future<List<ActerPin>> build() async {
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream('pins'); // keep it resident in memory
    _poller = _listener.listen((e) async {
      state = await AsyncValue.guard(_getPins);
    });
    ref.onDispose(() => _poller.cancel());
    return await _getPins();
  }
}

class AsyncPinNotifier
    extends AutoDisposeFamilyAsyncNotifier<ActerPin, String> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  Future<ActerPin> _getPin() async {
    final client = ref.read(alwaysClientProvider);
    return await client.waitForPin(arg, null);
  }

  @override
  Future<ActerPin> build(String arg) async {
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream(arg); // keep it resident in memory
    _poller = _listener.listen((e) async {
      state = await AsyncValue.guard(_getPin);
    }); // stay up to date
    ref.onDispose(() => _poller.cancel());
    return await _getPin();
  }
}

class AsyncSpacePinsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<ActerPin>, Space> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  Future<List<ActerPin>> _getPins() async {
    return (await arg.pins()).toList(); // this might throw internally
  }

  @override
  Future<List<ActerPin>> build(Space arg) async {
    final client = ref.watch(alwaysClientProvider);
    final spaceId = arg.getRoomId();
    _listener =
        client.subscribeStream('$spaceId::pins'); // keep it resident in memory
    _poller = _listener.listen((e) async {
      state = await AsyncValue.guard(_getPins);
    });
    ref.onDispose(() => _poller.cancel());
    return await _getPins();
  }
}
