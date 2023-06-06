import 'package:acter/features/chat/models/joined_room.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Invitation;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_list_state.freezed.dart';

@Freezed(makeCollectionsUnmodifiable: false)
class ChatListState with _$ChatListState {
  const factory ChatListState({
    @Default([]) List<JoinedRoom> joinedRooms,
    @Default([]) List<Invitation> invitations,
    @Default(false) bool showSearch,
    @Default([]) List<JoinedRoom> searchData,
    @Default(false) bool initialLoaded,
  }) = _ChatListState;
}
