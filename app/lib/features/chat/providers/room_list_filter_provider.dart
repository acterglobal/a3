import 'package:acter/features/chat/models/room_list_filter_state/room_list_filter_state.dart';
import 'package:riverpod/riverpod.dart';

final roomListFilterProvider =
    StateNotifierProvider<RoomListFilterNotifier, RoomListFilterState>(
  (ref) => RoomListFilterNotifier(),
);

final hasRoomFilters = StateProvider((ref) {
  final state = ref.watch(roomListFilterProvider);
  if (state.searchTerm != null && state.searchTerm!.isNotEmpty) {
    return true;
  }
  return state.selection != FilterSelection.all;
});

class RoomListFilterNotifier extends StateNotifier<RoomListFilterState> {
  RoomListFilterNotifier() : super(const RoomListFilterState());

  void setSelection(FilterSelection newFilter) {
    state = state.copyWith(selection: newFilter);
  }

  void updateSearchTerm(String? newTerm) {
    state = state.copyWith(searchTerm: newTerm);
  }

  void clear() {
    // reset to nothing
    state = const RoomListFilterState();
  }
}
