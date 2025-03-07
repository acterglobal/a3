import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

part 'chat_input_state.freezed.dart';

enum SelectedMessageState { none, actions, replyTo, edit }

enum SendingState { preparing, sending }

@freezed
class ChatInputState with _$ChatInputState {
  const factory ChatInputState({
    @Default(SelectedMessageState.none)
    SelectedMessageState selectedMessageState,
    @Default(SendingState.preparing) SendingState sendingState,
    @Default(false) bool emojiPickerVisible,
    @Default(null) types.Message? selectedMessage,
    @Default({}) Map<String, String> mentions,
    @Default(false) bool editBtnVisible,
  }) = _ChatInputState;
}
