import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomEventItem;

enum MessageAction { none, reply, edit }

class ChatEditorState {
  final RoomEventItem? selectedMsgItem;
  final MessageAction actionType;

  const ChatEditorState({
    this.selectedMsgItem,
    this.actionType = MessageAction.none,
  });

  bool get isReplying => actionType == MessageAction.reply;
  bool get isEditing => actionType == MessageAction.edit;

  ChatEditorState copyWith({
    RoomEventItem? selectedMsgItem,
    MessageAction? actionType,
  }) {
    return ChatEditorState(
      selectedMsgItem: selectedMsgItem ?? this.selectedMsgItem,
      actionType: actionType ?? this.actionType,
    );
  }
}
