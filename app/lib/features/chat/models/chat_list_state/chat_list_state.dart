import 'package:acter/features/chat/models/joined_room/joined_room.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_list_state.freezed.dart';

@Freezed(makeCollectionsUnmodifiable: false)
class ChatListState with _$ChatListState {
  const factory ChatListState({
    @Default(false) bool showSearch,
    @Default([]) List<JoinedRoom> searchData,
    @Default(false) bool initialLoaded,
  }) = _ChatListState;
}
