import 'package:acter/features/bookmarks/types.dart';
import 'package:acter/features/bookmarks/util.dart';
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
final pinListProvider =
    AsyncNotifierProvider.family<AsyncPinListNotifier, List<ActerPin>, String?>(
      () => AsyncPinListNotifier(),
    );

//All Pins List Provider
// Pins with the bookmarked pins in front
final pinsProvider = FutureProvider.autoDispose.family<List<ActerPin>, String?>(
  (ref, spaceId) async => priotizeBookmarked(
    ref,
    BookmarkType.pins,
    await ref.watch(pinListProvider(spaceId).future),
    getId: (t) => t.eventIdStr(),
  ),
);

//Pin list with it's own search value provider
final pinListSearchedProvider = FutureProvider.autoDispose
    .family<List<ActerPin>, String?>((ref, spaceId) async {
      final pinList = await ref.watch(pinsProvider(spaceId).future);
      final searchTerm =
          ref.watch(pinListSearchTermProvider).trim().toLowerCase();
      if (searchTerm.isEmpty) return pinList;
      return pinList
          .where((pin) => pin.title().toLowerCase().contains(searchTerm))
          .toList();
    });

//Pin list for quick search value provider
final pinListQuickSearchedProvider = FutureProvider.autoDispose<List<ActerPin>>(
  (ref) async {
    final pinList = await ref.watch(pinsProvider(null).future);
    final searchTerm = ref.watch(quickSearchValueProvider).trim().toLowerCase();
    if (searchTerm.isEmpty) return pinList;
    return pinList
        .where((pin) => pin.title().toLowerCase().contains(searchTerm))
        .toList();
  },
);

//Get single pin details
final pinProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncPinNotifier, ActerPin, String>(() => AsyncPinNotifier());

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
