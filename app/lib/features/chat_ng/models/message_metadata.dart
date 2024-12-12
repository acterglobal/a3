class MessageMetadata {
  final bool isUser;
  final bool isNextMessageInGroup;
  final bool wasEdited;
  final bool isNotice;
  final String? msgType;

  MessageMetadata({
    this.isUser = false,
    this.isNextMessageInGroup = false,
    this.wasEdited = false,
    this.isNotice = false,
    this.msgType,
  });
}
