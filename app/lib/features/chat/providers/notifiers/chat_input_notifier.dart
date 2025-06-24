import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatInputNotifier extends StateNotifier<ChatInputState> {
  ChatInputNotifier() : super(const ChatInputState());

  bool get isSending => state.sendingState == SendingState.sending;

  void emojiPickerVisible(bool value) =>
      state = state.copyWith(emojiPickerVisible: value);

  void addMention(String displayName, String authorId) {
    final mentions = Map.of(state.mentions);
    mentions[displayName] = authorId;
    state = state.copyWith(mentions: mentions);
  }

  void setReplyToMessage(Message message) {
    state = state.copyWith(
      selectedMessage: message,
      selectedMessageState: SelectedMessageState.replyTo,
    );
  }

  void setEditMessage(Message message) {
    state = state.copyWith(
      selectedMessage: message,
      selectedMessageState: SelectedMessageState.edit,
    );
  }

  void setActionsMessage(Message message) {
    state = state.copyWith(
      selectedMessage: message,
      selectedMessageState: SelectedMessageState.actions,
    );
  }

  void unsetActions() {
    if (state.selectedMessageState == SelectedMessageState.actions) {
      state = state.copyWith(
        selectedMessage: null,
        selectedMessageState: SelectedMessageState.none,
      );
    }
  }

  void unsetSelectedMessage() {
    state = state.copyWith(
      selectedMessage: null,
      selectedMessageState: SelectedMessageState.none,
    );
  }

  void startSending() {
    state = state.copyWith(sendingState: SendingState.sending);
  }

  void sendingFailed() {
    // reset the state;
    state = state.copyWith(sendingState: SendingState.preparing);
  }

  void messageSent() {
    // reset the state;
    state = state.copyWith(
      sendingState: SendingState.preparing,
      selectedMessage: null,
      selectedMessageState: SelectedMessageState.none,
      mentions: {},
    );
  }
}
