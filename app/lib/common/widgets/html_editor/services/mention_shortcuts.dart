import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/html_editor/components/mention_menu.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const userMentionTrigger = '@';
const roomMentionTrigger = '#';

List<CharacterShortcutEvent> getMentionShortcuts(
  BuildContext context,
  RoomQuery query,
) {
  return [
    CharacterShortcutEvent(
      character: userMentionTrigger,
      handler: (editorState) => _handleMentionTrigger(
        context: context,
        editorState: editorState,
        triggerChar: userMentionTrigger,
        query: query,
      ),
      key: userMentionTrigger,
    ),
    CharacterShortcutEvent(
      character: roomMentionTrigger,
      handler: (editorState) => _handleMentionTrigger(
        context: context,
        editorState: editorState,
        triggerChar: roomMentionTrigger,
        query: query,
      ),
      key: roomMentionTrigger,
    ),
  ];
}

Future<bool> _handleMentionTrigger({
  required BuildContext context,
  required EditorState editorState,
  required String triggerChar,
  required RoomQuery query,
}) async {
  final selection = editorState.selection;
  if (selection == null) return false;

  if (!selection.isCollapsed) {
    await editorState.deleteSelection(selection);
  }
  // Insert the trigger character
  await editorState.insertTextAtPosition(
    triggerChar,
    position: selection.start,
  );

  /// Riverpod code to fetch mention items here
  List<String> items = [];
  if (context.mounted) {
    final ref = ProviderScope.containerOf(context);
    // users of room
    if (triggerChar == '@') {
      items = await ref.read(membersIdsProvider(query.roomId).future);
    }
    // rooms
    if (triggerChar == '#') {
      items = await ref.read(chatIdsProvider);
    }
  }
  // Show menu
  if (context.mounted) {
    final menu = MentionMenu(
      context: context,
      editorState: editorState,
      items: items,
      mentionTrigger: triggerChar,
      style: const MentionMenuStyle.dark(),
    );

    menu.show();
  }
  return true;
}
