import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatInputNotifier extends StateNotifier<ChatInputState> {
  GlobalKey<FlutterMentionsState> mentionKey =
      GlobalKey<FlutterMentionsState>();
  FocusNode focusNode = FocusNode();
  Map<String, String> messageTextMapMarkDown = {};
  Map<String, String> messageTextMapHtml = {};

  ChatInputNotifier() : super(const ChatInputState()) {
    _init();
  }

  void _init() {
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        if (state.emojiVisible) {
          state = state.copyWith(emojiVisible: false);
        }
        if (state.attachmentVisible) {
          state = state.copyWith(attachmentVisible: false);
        }
      }
    });
  }

  void toggleReplyView() {
    state = state.copyWith(showReplyView: !state.showReplyView);
  }

  void showSendBtn(bool value) {
    state = state.copyWith(sendBtnVisible: value);
  }

  void toggleAttachment() {
    state = state.copyWith(attachmentVisible: !state.attachmentVisible);
  }

  void toggleEmoji() {
    state = state.copyWith(emojiVisible: !state.emojiVisible);
  }

  void setReplyWidget(Widget? child) {
    state = state.copyWith(replyWidget: child);
  }
}
