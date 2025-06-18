import 'package:acter/common/toolkit/html_editor/mentions/mention_menu.dart';
import 'package:acter/common/toolkit/html_editor/mentions/models/mention_type.dart';
import 'package:acter/common/toolkit/html_editor/services/constants.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

List<CharacterShortcutEvent> mentionShortcuts(
  BuildContext context,
  WidgetRef ref,
  String roomId,
) {
  return [
    CharacterShortcutEvent(
      character: userMentionChar,
      handler:
          (editorState) => _handleMentionTrigger(
            context: context,
            mentionType: MentionType.user,
            editorState: editorState,
            roomId: roomId,
            ref: ref,
          ),
      key: userMentionChar,
    ),
    CharacterShortcutEvent(
      character: roomMentionChar,
      handler:
          (editorState) => _handleMentionTrigger(
            context: context,
            mentionType: MentionType.room,
            editorState: editorState,
            roomId: roomId,
            ref: ref,
          ),
      key: roomMentionChar,
    ),
  ];
}

Future<bool> _handleMentionTrigger({
  required BuildContext context,
  required MentionType mentionType,
  required EditorState editorState,
  required String roomId,
  required WidgetRef ref,
}) async {
  final selection = editorState.selection;
  if (selection == null) return false;

  if (!selection.isCollapsed) {
    await editorState.deleteSelection(selection);
  }
  // Insert the trigger character
  await editorState.insertTextAtPosition(
    mentionType.character,
    position: selection.start,
  );

  // Show menu
  if (context.mounted) {
    final menu = MentionMenu(
      editorState: editorState,
      roomId: roomId,
      mentionType: mentionType,
      ref: ref,
    );

    menu.show(context);
  }
  return true;
}
