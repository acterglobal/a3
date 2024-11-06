import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/bookmarks/types.dart';
import 'package:acter/features/pins/models/create_pin_state/create_pin_state.dart';
import 'package:acter/features/pins/models/pin_edit_state/pin_edit_state.dart';
import 'package:acter/features/pins/providers/notifiers/create_pin_notifier.dart';
import 'package:acter/features/pins/providers/notifiers/edit_state_notifier.dart';
import 'package:acter/features/pins/providers/notifiers/pins_notifiers.dart';
import 'package:acter/features/search/providers/quick_search_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

//Search Value provider for pin list
final pinListSearchTermProvider = StateProvider<String>((ref) => '');

//SpaceId == null : GET LIST OF ALL PINs
//SpaceId != null : GET LIST OF SPACE PINs
final _pinsProvider =
    AsyncNotifierProvider.family<AsyncPinListNotifier, List<ActerPin>, String?>(
  () => AsyncPinListNotifier(),
);

//All Pins List Provider
final allPinListProvider =
    FutureProvider.autoDispose.family<List<ActerPin>, String?>(
  (ref, spaceId) async => await ref.watch(_pinsProvider(spaceId).future),
);

// Pins with the bookmarked pins in front
final allPinListWithBookmarkFrontProvider =
    FutureProvider.autoDispose.family<List<ActerPin>, String?>(
  (ref, spaceId) async {
    final pinList = await ref.watch(_pinsProvider(spaceId).future);
    final bookmarks =
        await ref.watch(bookmarkByTypeProvider(BookmarkType.pins).future);
    if (bookmarks.isEmpty) return pinList;

    //Put the bookmarked pins in the front
    final bookmarkedPins = <ActerPin>[];
    final otherPins = <ActerPin>[];

    for (final pin in pinList) {
      if (bookmarks.contains(pin.eventIdStr())) {
        bookmarkedPins.add(pin);
      } else {
        otherPins.add(pin);
      }
    }
    return [...bookmarkedPins, ...otherPins];
  },
);

//Pin list with it's own search value provider
final pinListSearchedProvider = FutureProvider.autoDispose
    .family<List<ActerPin>, String?>((ref, spaceId) async {
  final pinList =
      await ref.watch(allPinListWithBookmarkFrontProvider(spaceId).future);
  final searchTerm = ref.watch(pinListSearchTermProvider).trim().toLowerCase();
  if (searchTerm.isEmpty) return pinList;
  return pinList
      .where((pin) => pin.title().toLowerCase().contains(searchTerm))
      .toList();
});

//Pin list for quick search value provider
final pinListQuickSearchedProvider =
    FutureProvider.autoDispose<List<ActerPin>>((ref) async {
  final pinList =
      await ref.watch(allPinListWithBookmarkFrontProvider(null).future);
  final searchTerm = ref.watch(quickSearchValueProvider).trim().toLowerCase();
  if (searchTerm.isEmpty) return pinList;
  return pinList
      .where((pin) => pin.title().toLowerCase().contains(searchTerm))
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
