import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem;

enum MessageAction { none, reply, edit }

class ChatEditorState {
  final TimelineEventItem? selectedMsgItem;
  final MessageAction actionType;

  const ChatEditorState({
    this.selectedMsgItem,
    this.actionType = MessageAction.none,
  });

  bool get isReplying => actionType == MessageAction.reply;
  bool get isEditing => actionType == MessageAction.edit;

  ChatEditorState copyWith({
    TimelineEventItem? selectedMsgItem,
    MessageAction? actionType,
  }) {
    return ChatEditorState(
      selectedMsgItem: selectedMsgItem,
      actionType: actionType ?? this.actionType,
    );
  }
}
