import 'package:acter/common/providers/notifiers/client_pref_notifier.dart';
import 'package:acter/features/chat/models/room_list_filter_state/room_list_filter_state.dart';
import 'package:riverpod/riverpod.dart';

final persistentRoomListFilterSelector = createMapPrefProvider<FilterSelection>(
  prefKey: 'chatRoomFilterSelection',
  mapFrom: (v) => FilterSelection.values
      .firstWhere((e) => e.toString() == v, orElse: () => FilterSelection.all),
  mapTo: (v) => v.toString(),
);

final roomListFilterProvider =
    StateNotifierProvider<RoomListFilterNotifier, RoomListFilterState>(
  (ref) =>
      RoomListFilterNotifier(ref.read(persistentRoomListFilterSelector), ref),
);

final hasRoomFilters = StateProvider((ref) {
  final state = ref.watch(roomListFilterProvider);
  if (state.searchTerm != null && state.searchTerm!.isNotEmpty) {
    return true;
  }
  return state.selection != FilterSelection.all;
});

class RoomListFilterNotifier extends StateNotifier<RoomListFilterState> {
  RoomListFilterNotifier(FilterSelection selection, this.ref)
      : super(RoomListFilterState(selection: selection)) {
    ref.listen(persistentRoomListFilterSelector, (previous, next) {
      // the persistance loader might come back a little late ...
      if (state.selection != next) {
        // live update, apply
        state = state.copyWith(selection: next);
      }
    });
  }

  final Ref ref;

  Future<void> setSelection(FilterSelection newFilter) async {
    state = state.copyWith(selection: newFilter);
    await ref.read(persistentRoomListFilterSelector.notifier).update(newFilter);
  }

  void updateSearchTerm(String? newTerm) {
    state = state.copyWith(searchTerm: newTerm);
  }

  void clear() {
    // reset to nothing
    state = const RoomListFilterState();
  }
}
