import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

part 'chat_input_state.freezed.dart';

typedef UserRoomProfile = ({String? displayName, String userId});

enum SelectedMessageState {
  none,
  actions,
  replyTo,
  edit,
}

enum SendingState {
  preparing,
  sending,
}

enum SearchState {
  user,
  none,
  // for future purposes
  room
}

@freezed
class ChatInputState with _$ChatInputState {
  const factory ChatInputState({
    @Default('') String message,
    @Default(SelectedMessageState.none)
    SelectedMessageState selectedMessageState,
    @Default(SearchState.none) SearchState searchState,
    @Default(SendingState.preparing) SendingState sendingState,
    @Default(false) bool emojiPickerVisible,
    @Default(false) bool searchLoading,
    @Default(null) types.Message? selectedMessage,
    @Default([]) List<UserRoomProfile> roomMembers,
    @Default(false) bool editBtnVisible,
  }) = _ChatInputState;
}
