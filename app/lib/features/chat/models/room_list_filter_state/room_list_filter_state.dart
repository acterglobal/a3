import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod/riverpod.dart';

part 'room_list_filter_state.freezed.dart';

Future<bool> roomListFilterStateAppliesToRoom(
  RoomListFilterState state,
  Ref ref,
  Convo convo,
) async {
  switch (state.selection) {
    case FilterSelection.dmsOnly:
      if (!convo.isDm()) {
        return false;
      }
      break;
    case FilterSelection.favorites:
      if (!convo.isFavorite()) {
        return false;
      }
      break;
    default: // all other case just continue
      break;
  }
  if (state.searchTerm?.isNotEmpty == true) {
    final searchTerm = state.searchTerm!.toLowerCase();
    if (convo.getRoomIdStr().toLowerCase().contains(searchTerm)) {
      return true;
    }
    final profile = await ref.watch(chatProfileDataProvider(convo).future);
    if (profile.displayName != null &&
        profile.displayName!.toLowerCase().contains(searchTerm)) {
      return true;
    }
    return false;
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
