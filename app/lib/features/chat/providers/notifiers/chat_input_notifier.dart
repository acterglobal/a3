import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatInputNotifier extends StateNotifier<ChatInputState> {
  ChatInputNotifier() : super(const ChatInputState());

  void toggleReplyView() =>
      state = state.copyWith(showReplyView: !state.showReplyView);

  void toogleSendBtn() =>
      state = state.copyWith(sendBtnVisible: !state.sendBtnVisible);

  void toggleAttachment() =>
      state = state.copyWith(attachmentVisible: !state.attachmentVisible);

  void toggleEmojiBtn() =>
      state = state.copyWith(emojiBtnVisible: !state.emojiBtnVisible);

  void setReplyWidget(Widget? child) =>
      state = state.copyWith(replyWidget: child);
}
