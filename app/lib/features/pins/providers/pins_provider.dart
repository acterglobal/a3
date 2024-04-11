import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/pins/models/pin_edit_state/pin_edit_state.dart';
import 'package:acter/features/pins/providers/notifiers/edit_state_notifier.dart';
import 'package:acter/features/pins/providers/notifiers/pins_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

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

final pinEditProvider = StateNotifierProvider.family
    .autoDispose<PinEditNotifier, PinEditState, ActerPin>(
  (ref, pin) => PinEditNotifier(pin: pin, ref: ref),
);

