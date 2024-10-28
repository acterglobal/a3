import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/bookmarks/types.dart';
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

// Pins with the bookmarked pins in front
final pinsProvider = FutureProvider.autoDispose
    .family<List<ActerPin>, String?>((ref, spaceId) async {
  final bookmarks =
      await ref.watch(bookmarkByTypeProvider(BookmarkType.pins).future);
  final pins = await ref.watch(pinListProvider(spaceId).future);
  if (bookmarks.isEmpty) {
    return pins;
  }
  // put the bookmarked pins in the front
  final returnPins =
      List<ActerPin?>.filled(bookmarks.length, null, growable: true);
  final remaining = List<ActerPin>.empty(growable: true);
  for (final pin in pins) {
    final index = bookmarks.indexOf(pin.eventIdStr());
    if (index != -1) {
      returnPins[index] = pin;
    } else {
      remaining.add(pin);
    }
  }
  return returnPins
      .where((a) => a != null)
      .cast<ActerPin>()
      .followedBy(remaining)
      .toList();
});

final pinListSearchProvider = FutureProvider.autoDispose
    .family<List<ActerPin>, AllPinsSearchParams>((ref, params) async {
  final pinList = await ref.watch(pinsProvider(params.spaceId).future);
  final search = params.searchText.toLowerCase();
  if (search.isEmpty) return pinList;
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
