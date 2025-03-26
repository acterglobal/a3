import 'package:acter/features/chat_ng/models/chat_editor_state.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatEditorNotifier extends AutoDisposeNotifier<ChatEditorState> {
  ChatEditorNotifier() : super();

  @override
  ChatEditorState build() =>
      state = ChatEditorState(
        selectedMsgItem: null,
        actionType: MessageAction.none,
      );
  void setReplyToMessage(TimelineEventItem msgItem) {
    state = state.copyWith(
      selectedMsgItem: msgItem,
      actionType: MessageAction.reply,
    );
  }

  void setEditMessage(TimelineEventItem msgItem) {
    state = state.copyWith(
      selectedMsgItem: msgItem,
      actionType: MessageAction.edit,
    );
  }

  void unsetActions() {
    if (state.actionType != MessageAction.none) {
      state = state.copyWith(
        selectedMsgItem: null,
        actionType: MessageAction.none,
      );
    }
  }
}
