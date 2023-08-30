import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatInputNotifier extends StateNotifier<ChatInputState> {
  ChatInputNotifier() : super(const ChatInputState());

  void toggleReplyView(bool value) =>
      state = state.copyWith(showReplyView: value);

  void showSendBtn(bool value) => state = state.copyWith(sendBtnVisible: value);

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
}
