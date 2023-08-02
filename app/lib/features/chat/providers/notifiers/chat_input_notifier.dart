import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatInputNotifier extends StateNotifier<ChatInputState> {
  ChatInputNotifier() : super(const ChatInputState());

  void setReplyView(bool value) {
    state = state.copyWith(showReplyView: value);
  }

  void showSendBtn(bool value) {
    state = state.copyWith(sendBtnVisible: value);
  }

  void toggleAttachment() {
    state = state.copyWith(attachmentVisible: !state.attachmentVisible);
  }

  void emojiRowVisible(bool value) =>
      state = state.copyWith(emojiRowVisible: value);

  void emojiPickerVisible(bool value) =>
      state = state.copyWith(emojiPickerVisible: value);

  void setReplyWidget(Widget? child) {
    state = state.copyWith(replyWidget: child);
  }
}
