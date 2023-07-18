import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_input_state.freezed.dart';

@freezed
class ChatInputState with _$ChatInputState {
  const factory ChatInputState({
    @Default(false) bool showReplyView,
    @Default(null) Widget? replyWidget,
    @Default(false) bool sendBtnVisible,
    @Default(false) bool emojiBtnVisible,
    @Default(false) bool attachmentVisible,
  }) = _ChatInputState;
}
