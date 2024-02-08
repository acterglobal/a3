import 'dart:core';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/pins/providers/notifiers/pins_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pinsProvider =
    AsyncNotifierProvider.autoDispose<AsyncPinsNotifier, List<ActerPin>>(
  () => AsyncPinsNotifier(),
);

final pinProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncPinNotifier, ActerPin, String>(
  () => AsyncPinNotifier(),
);

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
