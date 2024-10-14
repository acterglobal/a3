import 'package:acter/features/pins/models/create_pin_state/create_pin_state.dart';
import 'package:acter/features/pins/models/pin_edit_state/pin_edit_state.dart';
import 'package:acter/features/pins/providers/notifiers/create_pin_notifier.dart';
import 'package:acter/features/pins/providers/notifiers/edit_state_notifier.dart';
import 'package:acter/features/pins/providers/notifiers/pins_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

//SpaceId == null : GET LIST OF ALL PINs
//SpaceId != null : GET LIST OF SPACE PINs
final pinListProvider =
    AsyncNotifierProvider.family<AsyncPinListNotifier, List<ActerPin>, String?>(
  () => AsyncPinListNotifier(),
);

//Search any pins
typedef AllPinsSearchParams = ({String? spaceId, String searchText});

final pinListSearchProvider = FutureProvider.autoDispose
    .family<List<ActerPin>, AllPinsSearchParams>((ref, params) async {
  final pinList = await ref.watch(pinListProvider(params.spaceId).future);
  if (params.searchText.isEmpty) return pinList;
  final search = params.searchText.toLowerCase();
  return pinList
      .where((pin) => pin.title().toLowerCase().contains(search))
      .toList();
});

//Get single pin details
final pinProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncPinNotifier, ActerPin, String>(
  () => AsyncPinNotifier(),
);

//Update single pin details
final pinEditProvider = StateNotifierProvider.family
    .autoDispose<PinEditNotifier, PinEditState, ActerPin>(
  (ref, pin) => PinEditNotifier(pin: pin, ref: ref),
);

// Create Pin State
final createPinStateProvider =
    StateNotifierProvider.autoDispose<CreatePinNotifier, CreatePinState>(
  (ref) => CreatePinNotifier(),
);
