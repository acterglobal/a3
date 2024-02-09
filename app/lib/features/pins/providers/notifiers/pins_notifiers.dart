import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncPinsNotifier extends AutoDisposeAsyncNotifier<List<ActerPin>> {
  late Stream<void> _listener;

  Future<List<ActerPin>> _getPins() async {
    final client = ref.watch(alwaysClientProvider);
    return (await client.pins()).toList(); // this might throw internally
  }

  @override
  Future<List<ActerPin>> build() async {
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream('pins'); // stay up to date
    _listener.forEach((e) async {
      state = await AsyncValue.guard(() => _getPins());
    });
    return _getPins();
  }
}

class AsyncPinNotifier
    extends AutoDisposeFamilyAsyncNotifier<ActerPin, String> {
  late Stream<void> _listener;

  Future<ActerPin> _getPin() async {
    final client = ref.watch(alwaysClientProvider);
    return await client.waitForPin(arg, null);
  }

  @override
  Future<ActerPin> build(String arg) async {
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream(arg); // stay up to date
    _listener.forEach((e) async {
      state = await AsyncValue.guard(() => _getPin());
    });
    return _getPin();
  }
}

class AsyncSpacePinsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<ActerPin>, Space> {
  late Stream<void> _listener;

  Future<List<ActerPin>> _getPins() async {
    return (await arg.pins()).toList(); // this might throw internally
  }

  @override
  Future<List<ActerPin>> build(Space arg) async {
    final client = ref.watch(alwaysClientProvider);
    final spaceId = arg.getRoomId();
    _listener = client.subscribeStream('$spaceId::pins'); // stay up to date
    _listener.forEach((e) async {
      state = await AsyncValue.guard(() => _getPins());
    });
    return _getPins();
  }
}
