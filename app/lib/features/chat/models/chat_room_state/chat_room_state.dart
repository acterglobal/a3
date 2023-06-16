import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Member;
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' show User, Message;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_room_state.freezed.dart';

@freezed
class ChatRoomState with _$ChatRoomState {
  const factory ChatRoomState({
    @Default(false) bool isLoaded,
    @Default([]) List<User> typingUsers,
    @Default([]) List<Member> activeMembers,
    @Default(null) Widget? replyMessageWidget,
    @Default(null) Message? repliedToMessage,
  }) = _ChatRoomState;
}
