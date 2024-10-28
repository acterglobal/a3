import 'package:acter/common/providers/room_providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod/riverpod.dart';

part 'room_list_filter_state.freezed.dart';

Future<bool> roomListFilterStateAppliesToRoom(
  RoomListFilterState state,
  Ref ref,
  String convoId,
) async {
  switch (state.selection) {
    case FilterSelection.dmsOnly:
      final isDm = await ref.watch(isDirectChatProvider(convoId).future);
      if (!isDm) return false;
      break;
    case FilterSelection.favorites:
      final bookmarked = await ref.watch(isConvoBookmarked(convoId).future);
      if (!bookmarked) return false;
      break;
    default: // all other case just continue
      break;
  }
  final searchTerm = state.searchTerm;
  if (searchTerm != null && searchTerm.isNotEmpty) {
    final search = searchTerm.toLowerCase();
    if (convoId.toLowerCase().contains(search)) return true;
    final displayName = await ref.read(roomDisplayNameProvider(convoId).future);
    return displayName?.toLowerCase().contains(search) == true;
  }
  return true;
}

enum FilterSelection {
  all,
  dmsOnly,
  favorites,
}

@freezed
class RoomListFilterState with _$RoomListFilterState {
  const factory RoomListFilterState({
    String? searchTerm,
    @Default(FilterSelection.all) FilterSelection selection,
  }) = _RoomListFilterState;
}
