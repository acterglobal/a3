import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatInputNotifier extends StateNotifier<ChatInputState> {
  ChatInputNotifier() : super(const ChatInputState());

  void toggleReplyView() {
    state = state.copyWith(showReplyView: !state.showReplyView);
  }

  void showSendBtn(bool value) {
    state = state.copyWith(sendBtnVisible: value);
  }

  void toggleAttachment() {
    state = state.copyWith(attachmentVisible: !state.attachmentVisible);
  }

  void emojiRowVisible() =>
      state = state.copyWith(emojiRowVisible: !state.emojiRowVisible);

  void emojiPickerVisible() =>
      state = state.copyWith(emojiPickerVisible: !state.emojiPickerVisible);

  void setReplyWidget(Widget? child) {
    state = state.copyWith(replyWidget: child);
  }
}
