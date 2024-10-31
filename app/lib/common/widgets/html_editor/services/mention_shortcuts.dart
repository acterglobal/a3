import 'package:acter/common/widgets/html_editor/components/mention_block.dart';
import 'package:acter/common/widgets/html_editor/components/mention_menu.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

List<CharacterShortcutEvent> mentionShortcuts(
  BuildContext context,
  String roomId,
) {
  return [
    CharacterShortcutEvent(
      character: '@',
      handler: (editorState) => _handleMentionTrigger(
        context: context,
        editorState: editorState,
        type: MentionType.user,
        roomId: roomId,
      ),
      key: '@',
    ),
    CharacterShortcutEvent(
      character: '#',
      handler: (editorState) => _handleMentionTrigger(
        context: context,
        editorState: editorState,
        type: MentionType.room,
        roomId: roomId,
      ),
      key: '#',
    ),
  ];
}

Future<bool> _handleMentionTrigger({
  required BuildContext context,
  required EditorState editorState,
  required MentionType type,
  required String roomId,
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
      roomId: roomId,
      mentionType: type,
      style: const MentionMenuStyle.dark(),
    );

    menu.show();
  }
  return true;
}
