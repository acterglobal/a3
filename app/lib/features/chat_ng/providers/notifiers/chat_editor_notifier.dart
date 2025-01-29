import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomEventItem;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MessageAction { none, reply, edit }

class ChatEditorState {
  final Widget? selectedMessage;
  final RoomEventItem? selectedMsgItem;
  final MessageAction actionType;

  const ChatEditorState({
    this.selectedMessage,
    this.selectedMsgItem,
    this.actionType = MessageAction.none,
  });

  bool get isReplying => actionType == MessageAction.reply;
  bool get isEditing => actionType == MessageAction.edit;

  ChatEditorState copyWith({
    Widget? selectedMessage,
    RoomEventItem? selectedMsgItem,
    MessageAction? actionType,
  }) {
    return ChatEditorState(
      selectedMessage: selectedMessage ?? this.selectedMessage,
      selectedMsgItem: selectedMsgItem ?? this.selectedMsgItem,
      actionType: actionType ?? this.actionType,
    );
  }
}

class ChatEditorNotifier extends AutoDisposeNotifier<ChatEditorState> {
  ChatEditorNotifier() : super();

  @override
  ChatEditorState build() => state = ChatEditorState(
        selectedMessage: null,
        selectedMsgItem: null,
        actionType: MessageAction.none,
      );
  void setReplyToMessage(Widget message, RoomEventItem msgItem) {
    state = state.copyWith(
      selectedMessage: message,
      selectedMsgItem: msgItem,
      actionType: MessageAction.reply,
    );
  }

  void setEditMessage(
    Widget message,
    RoomEventItem msgItem,
  ) {
    state = state.copyWith(
      selectedMessage: message,
      selectedMsgItem: msgItem,
      actionType: MessageAction.edit,
    );
  }

  void unsetActions() {
    if (state.actionType != MessageAction.none) {
      state = state.copyWith(
        selectedMessage: null,
        selectedMsgItem: null,
        actionType: MessageAction.none,
      );
    }
  }
}
