import 'package:acter/common/models/types.dart';
import 'package:acter/common/widgets/html_editor/components/mention_block.dart';
import 'package:acter/common/widgets/html_editor/components/mention_menu.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

List<CharacterShortcutEvent> getMentionShortcuts(
  BuildContext context,
  RoomQuery query,
) {
  return [
    CharacterShortcutEvent(
      character: '@',
      handler: (editorState) => _handleMentionTrigger(
        context: context,
        editorState: editorState,
        type: MentionType.user,
        query: query,
      ),
      key: '@',
    ),
    CharacterShortcutEvent(
      character: '#',
      handler: (editorState) => _handleMentionTrigger(
        context: context,
        editorState: editorState,
        type: MentionType.room,
        query: query,
      ),
      key: '#',
    ),
  ];
}

Future<bool> _handleMentionTrigger({
  required BuildContext context,
  required EditorState editorState,
  required MentionType type,
  required RoomQuery query,
}) async {
  final selection = editorState.selection;
  if (selection == null) return false;

  if (!selection.isCollapsed) {
    await editorState.deleteSelection(selection);
  }
  // Insert the trigger character
  await editorState.insertTextAtPosition(
    MentionType.toStr(type),
    position: selection.start,
  );

  // Show menu
  if (context.mounted) {
    final menu = MentionMenu(
      context: context,
      editorState: editorState,
      query: query,
      mentionType: type,
      style: const MentionMenuStyle.dark(),
    );

    menu.show();
  }
  return true;
}
