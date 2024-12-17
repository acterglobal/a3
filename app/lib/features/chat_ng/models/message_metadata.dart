class MessageMetadata {
  final String roomId;
  final String messageId;
  final bool isUser;
  final bool isNextMessageInGroup;
  final bool wasEdited;
  final bool isNotice;
  final bool isReply;
  final String? msgType;
  final String? repliedTo;

  MessageMetadata({
    required this.roomId,
    required this.messageId,
    this.isUser = false,
    this.isNextMessageInGroup = false,
    this.wasEdited = false,
    this.isNotice = false,
    this.isReply = false,
    this.msgType,
    this.repliedTo,
  });

  MessageMetadata copyWith({
    String? roomId,
    String? messageId,
    bool? isUser,
    bool? isNextMessageInGroup,
    bool? wasEdited,
    bool? isNotice,
    bool? isReply,
    String? msgType,
    String? repliedTo,
  }) {
    return MessageMetadata(
      roomId: roomId ?? this.roomId,
      messageId: messageId ?? this.messageId,
      isUser: isUser ?? this.isUser,
      isNextMessageInGroup: isNextMessageInGroup ?? this.isNextMessageInGroup,
      wasEdited: wasEdited ?? this.wasEdited,
      isNotice: isNotice ?? this.isNotice,
      isReply: isReply ?? this.isReply,
      msgType: msgType ?? this.msgType,
      repliedTo: repliedTo ?? this.repliedTo,
    );
  }
}
