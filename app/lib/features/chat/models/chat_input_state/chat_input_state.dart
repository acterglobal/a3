import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

part 'chat_input_state.freezed.dart';

@freezed
class ChatInputState with _$ChatInputState {
  const factory ChatInputState({
    @Default(false) bool showReplyView,
    @Default(null) Widget? replyWidget,
    @Default(true) bool allowEdit,
    @Default(false) bool sendBtnVisible,
    @Default(false) bool emojiRowVisible,
    @Default(false) bool emojiPickerVisible,
    @Default(false) bool attachmentVisible,
    @Default([]) List<File> fileList,
    @Default(null) String? currentMessageId,
    @Default(null) types.Message? repliedToMessage,
    @Default({}) Map<String, String> mentionReplacements,
  }) = _ChatInputState;
}
