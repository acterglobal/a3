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
    extends FamilyAsyncNotifier<List<ActerPin>, Space> {
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

class AsyncPinListNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<ActerPin>, String?> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  @override
  Future<List<ActerPin>> build(String? arg) async {
    final client = ref.watch(alwaysClientProvider);

    //GET ALL PINS
    if (arg == null) {
      _listener = client.subscribeStream('pins');
    }
    //GET SPACE PINS
    else {
      _listener = client.subscribeStream('$arg::pins');
    }

    _poller = _listener.listen((e) async {
      state = await AsyncValue.guard(() => _getPinList(client));
    });
    ref.onDispose(() => _poller.cancel());
    return await _getPinList(client);
  }

  Future<List<ActerPin>> _getPinList(Client client) async {
    //GET ALL PINS
    if (arg == null) {
      return (await client.pins()).toList(); // this might throw internally
    }
    //GET SPACE PINS
    else {
      final space = await client.space(arg!);
      return (await space.pins()).toList(); // this might throw internally
    }
  }
}
