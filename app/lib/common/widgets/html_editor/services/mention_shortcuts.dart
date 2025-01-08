import 'package:acter/common/widgets/html_editor/components/mention_menu.dart';
import 'package:acter/common/widgets/html_editor/models/mention_type.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

List<CharacterShortcutEvent> mentionShortcuts(
  BuildContext context,
  String roomId,
) {
  return [
    CharacterShortcutEvent(
      character: userMentionChar,
      handler: (editorState) => _handleMentionTrigger(
        context: context,
        mentionTrigger: userMentionChar,
        editorState: editorState,
        roomId: roomId,
      ),
      key: userMentionChar,
    ),
    CharacterShortcutEvent(
      character: roomMentionChar,
      handler: (editorState) => _handleMentionTrigger(
        context: context,
        mentionTrigger: roomMentionChar,
        editorState: editorState,
        roomId: roomId,
      ),
      key: roomMentionChar,
    ),
  ];
}

Future<bool> _handleMentionTrigger({
  required BuildContext context,
  required String mentionTrigger,
  required EditorState editorState,
  required String roomId,
}) async {
  final selection = editorState.selection;
  if (selection == null) return false;

  if (!selection.isCollapsed) {
    await editorState.deleteSelection(selection);
  }

  // Check if the current menu is already showing
  final isMenuVisible = MentionOverlayState.currentMenu != null;

  // If the same mention trigger is typed twice consecutively, dismiss the menu
  if (isMenuVisible &&
      MentionOverlayState.currentMenu?.mentionTrigger == mentionTrigger) {
    MentionOverlayState.dismiss();
    MentionOverlayState.currentMenu = null;
    return true;
  }

  MentionOverlayState.currentMenu = null;
  MentionOverlayState.dismiss();

  // Insert the mention trigger character
  await editorState.insertTextAtPosition(
    mentionTrigger,
    position: selection.start,
  );

  // Show the menu
  if (context.mounted) {
    final menu = MentionMenu(
      context: context,
      editorState: editorState,
      roomId: roomId,
      mentionTrigger: mentionTrigger,
    );
    MentionOverlayState.currentMenu = menu;
    menu.show();
  }
  return true;
}
