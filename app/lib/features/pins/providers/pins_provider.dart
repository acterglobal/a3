import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'dart:core';

class AsyncSpacePinsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<ActerPin>, Space> {
  late Stream<void> _listener;
  Future<List<ActerPin>> _getPins() async {
    return (await arg.pins()).toList(); // this might throw internally
  }

  @override
  Future<List<ActerPin>> build(Space arg) async {
    final client = ref.watch(clientProvider)!;
    final spaceId = arg.getRoomId();
    _listener = client.subscribeStream('$spaceId::PINS'); // stay up to date
    _listener.forEach((e) async {
      state = await AsyncValue.guard(() => _getPins());
    });
    return _getPins();
  }
}

final spacePinsProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncSpacePinsNotifier, List<ActerPin>, Space>(
  () => AsyncSpacePinsNotifier(),
);

final pinnedProvider = FutureProvider.autoDispose
    .family<List<ActerPin>, String>((ref, spaceId) async {
  final space = await ref.watch(spaceProvider(spaceId).future);
  return await ref.watch(spacePinsProvider(space).future);
});

final pinnedLinksProvider = FutureProvider.autoDispose
    .family<List<ActerPin>, String>((ref, spaceId) async {
  final space = await ref.watch(spaceProvider(spaceId).future);
  final pins = await ref.watch(spacePinsProvider(space).future);
  return pins.where((element) => element.isLink()).toList();
});

class AsyncPinsNotifier extends AutoDisposeAsyncNotifier<List<ActerPin>> {
  late Stream<void> _listener;
  Future<List<ActerPin>> _getPins() async {
    final client = ref.watch(clientProvider)!;
    return (await client.pins()).toList(); // this might throw internally
  }

  @override
  Future<List<ActerPin>> build() async {
    final client = ref.watch(clientProvider)!;
    _listener = client.subscribeStream('PINS'); // stay up to date
    _listener.forEach((e) async {
      state = await AsyncValue.guard(() => _getPins());
    });
    return _getPins();
  }
}

final pinsProvider =
    AsyncNotifierProvider.autoDispose<AsyncPinsNotifier, List<ActerPin>>(
  () => AsyncPinsNotifier(),
);

class AsyncPinNotifier
    extends AutoDisposeFamilyAsyncNotifier<ActerPin, String> {
  late Stream<void> _listener;
  Future<ActerPin> _getPin() async {
    final client = ref.watch(clientProvider)!;
    try {
      return await client.pin(arg);
    } catch (e) {
      return await client.waitForPin(arg, null);
    }
    // this might throw internally
  }

  @override
  Future<ActerPin> build(String arg) async {
    final client = ref.watch(clientProvider)!;
    _listener = client.subscribeStream(arg); // stay up to date
    _listener.forEach((e) async {
      state = await AsyncValue.guard(() => _getPin());
    });
    return _getPin();
  }
}

final pinProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncPinNotifier, ActerPin, String>(
  () => AsyncPinNotifier(),
);
