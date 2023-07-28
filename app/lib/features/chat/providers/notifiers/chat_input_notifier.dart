import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatInputNotifier extends StateNotifier<ChatInputState> {
  ChatInputNotifier() : super(const ChatInputState());

  void toggleReplyView() {
    if (mounted) {
      state = state.copyWith(showReplyView: !state.showReplyView);
    }
  }

  void showSendBtn(bool value) {
    if (mounted) {
      state = state.copyWith(sendBtnVisible: value);
    }
  }

  void toggleAttachment() {
    if (mounted) {
      state = state.copyWith(attachmentVisible: !state.attachmentVisible);
    }
  }

  void emojiRowVisible() {
    if (mounted) {
      state = state.copyWith(emojiRowVisible: !state.emojiRowVisible);
    }
  }

  void emojiPickerVisible() {
    if (mounted) {
      state = state.copyWith(emojiPickerVisible: !state.emojiPickerVisible);
    }
  }

  void setReplyWidget(Widget? child) {
    if (mounted) {
      state = state.copyWith(replyWidget: child);
    }
  }
}
