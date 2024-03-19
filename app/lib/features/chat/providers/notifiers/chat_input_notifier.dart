import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:riverpod/riverpod.dart';

class ChatInputNotifier extends StateNotifier<ChatInputState> {
  ChatInputNotifier() : super(const ChatInputState());

  void showEditView(bool value) => state = state.copyWith(showEditView: value);

  void showReplyView(bool value) =>
      state = state.copyWith(showReplyView: value);

  void showSendBtn(bool value) => state = state.copyWith(sendBtnVisible: value);

  void showEditButton(bool value) =>
      state = state.copyWith(editBtnVisible: value);

  void toggleAttachment(bool value) =>
      state = state.copyWith(attachmentVisible: value);

  void emojiRowVisible(bool value) =>
      state = state.copyWith(emojiRowVisible: value);

  void emojiPickerVisible(bool value) =>
      state = state.copyWith(emojiPickerVisible: value);

  void setReplyWidget(Widget? child) {
    if (mounted) {
      state = state.copyWith(replyWidget: child);
    }
  }

  void setEditWidget(Widget? child) {
    if (mounted) {
      state = state.copyWith(editWidget: child);
    }
  }

  void addMention(String displayName, String authorId) {
    final mentionReplacements = Map.of(state.mentionReplacements);
    mentionReplacements['@$displayName'] =
        '[$displayName](https://matrix.to/#/$authorId)';
    state = state.copyWith(mentionReplacements: mentionReplacements);
  }

  void setMentions(List<Map<String, String>> mentions) =>
      state = state.copyWith(mentions: mentions);

  void setRepliedToMessage(Message? message) {
    state = state.copyWith(repliedToMessage: message);
  }

  void setEditMessage(Message? message) {
    state = state.copyWith(editMessage: message);
  }

  void setCurrentMessageId(String? messageId) {
    state = state.copyWith(currentMessageId: messageId);
  }

  void prepareSending() {
    state = state.copyWith(sendBtnVisible: false, allowEdit: false);
  }

  void sendingFailed() {
    // reset the state;
    state = state.copyWith(sendBtnVisible: true, allowEdit: true);
  }

  void messageSent() {
    // reset the state;
    state = const ChatInputState().copyWith(
      mentions: state.mentions,
    );
  }
}
