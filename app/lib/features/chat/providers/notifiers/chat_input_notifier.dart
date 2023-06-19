import 'dart:typed_data';

import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
// import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
//     show FfiBufferUint8;
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatInputNotifier extends StateNotifier<ChatInputState> {
  final Ref ref;
  FocusNode focusNode = FocusNode();
  GlobalKey<FlutterMentionsState> mentionKey =
      GlobalKey<FlutterMentionsState>();
  String? authorId;

  ChatInputNotifier(this.ref) : super(const ChatInputState()) {
    _init();
  }

  void _init() {
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        state = state.copyWith(
          isEmojiContainerVisible: false,
          isAttachmentVisible: false,
        );
      }
    });
    ref.onDispose(() {
      focusNode.removeListener(() {});
    });
  }

  void setChatInputState({
    Map<String, String>? names,
    Map<String, Uint8List>? avatars,
    Map<String, String>? messageTextMapMarkDown,
    Map<String, String>? messageTextMapHtml,
    List<Map<String, dynamic>>? mentions,
    bool? isAttachmentVisible,
    bool? isEmojiVisible,
    bool? isEmojiContainerVisible,
    bool? isSendButtonVisible,
    bool? showReplyView,
  }) {
    state = state.copyWith(
      userAvatars: avatars ?? state.userAvatars,
      usernames: names ?? state.usernames,
      mentionList: mentions ?? state.mentionList,
      isAttachmentVisible: isAttachmentVisible ?? state.isAttachmentVisible,
      isEmojiVisible: isEmojiVisible ?? state.isEmojiVisible,
      isEmojiContainerVisible:
          isEmojiContainerVisible ?? state.isEmojiContainerVisible,
      isSendButtonVisible: isSendButtonVisible ?? state.isSendButtonVisible,
      showReplyView: showReplyView ?? state.showReplyView,
      messageTextMapMarkDown:
          messageTextMapMarkDown ?? state.messageTextMapMarkDown,
      messageTextMapHtml: messageTextMapHtml ?? state.messageTextMapHtml,
    );
  }

  /// Update button state based on text editor.
  void sendButtonUpdate() => state = state.copyWith(
        isSendButtonVisible:
            mentionKey.currentState!.controller!.text.trim().isNotEmpty,
      );

  /// Disable button as soon as send button is pressed.
  void sendButtonDisable() =>
      state = state.copyWith(isSendButtonVisible: !state.isSendButtonVisible);

  void toggleEmojiContainer() => state =
      state.copyWith(isEmojiContainerVisible: !state.isEmojiContainerVisible);

  void updateEmojiState(types.Message message) {
    final _messages = ref.read(chatMessagesProvider);
    int emojiMessageIndex = _messages.indexWhere((x) => x.id == message.id);
    String? emojiCurrentId = _messages[emojiMessageIndex].id;
    if (emojiCurrentId == message.id) {
      state = state.copyWith(
        isEmojiContainerVisible: !state.isEmojiContainerVisible,
      );
    }

    if (state.isEmojiContainerVisible) {
      authorId = message.author.id;
    }
  }

  bool isAuthor() {
    final myId = ref.read(clientProvider)!.userId().toString();
    return myId == authorId;
  }

  Uint8List? getUserAvatar(String userId) =>
      state.userAvatars.containsKey(userId) ? state.userAvatars[userId] : null;

  String? getUserName(String userId) =>
      state.usernames.containsKey(userId) ? state.usernames[userId] : null;

  void reset() {
    state = state.copyWith(
      userAvatars: {},
      usernames: {},
      mentionList: [],
      isAttachmentVisible: false,
      isEmojiVisible: false,
      isEmojiContainerVisible: false,
      isSendButtonVisible: false,
    );
  }
}
