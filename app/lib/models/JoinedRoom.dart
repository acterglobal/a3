import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Conversation, FfiBufferUint8, RoomMessage;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class JoinedRoom {
  Conversation conversation;
  RoomMessage? latestMessage;
  Future<FfiBufferUint8>? avatar;
  String? displayName;

  List<types.User> typingUsers = [];

  JoinedRoom({
    required this.conversation,
    this.latestMessage,
    this.avatar,
    this.displayName,
  });
}
