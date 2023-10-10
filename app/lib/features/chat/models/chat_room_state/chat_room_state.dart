import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

part 'chat_room_state.freezed.dart';

///Extension Method for easy comparison
extension ChatRoomLoadingStateGetters on ChatRoomLoadingState {
  bool get isLoading => this is _ChatRoomLoadingStateLoading;
}

@freezed
class ChatRoomLoadingState with _$ChatRoomLoadingState {
  ///Loading
  const factory ChatRoomLoadingState.loading() = _ChatRoomLoadingStateLoading;

  ///Data
  const factory ChatRoomLoadingState.loaded() = _ChatRoomLoadingStateLoaded;

  ///Error
  const factory ChatRoomLoadingState.error([String? error]) =
      _ChatRoomLoadingStateError;
}

@freezed
class ChatRoomState with _$ChatRoomState {
  const factory ChatRoomState({
    @Default([]) List<Message> messages,
    @Default({}) Map<String, List<String>> userReceipts,
    @Default(ChatRoomLoadingState.loading()) ChatRoomLoadingState loading,
    @Default(true) bool hasMore,
  }) = _ChatRoomState;
}
