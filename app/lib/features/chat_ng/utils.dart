import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> saveMsgDraft(
  String text,
  String? htmlText,
  String roomId,
  WidgetRef ref,
) async {
  // get the convo object to initiate draft
  final chat = await ref.read(chatProvider(roomId).future);
  final chatEditorState = ref.read(chatEditorStateProvider);
  final messageId = chatEditorState.selectedMsgItem?.eventId();

  if (chat != null) {
    if (messageId != null) {
      if (chatEditorState.isEditing) {
        await chat.saveMsgDraft(text, htmlText, 'edit', messageId);
      } else if (chatEditorState.isReplying) {
        await chat.saveMsgDraft(text, htmlText, 'reply', messageId);
      }
    } else {
      await chat.saveMsgDraft(text, htmlText, 'new', null);
    }
  }
}
