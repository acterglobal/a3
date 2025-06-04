import 'package:acter/common/toolkit/html_editor/services/mention_detection.dart';
import 'package:acter/features/deep_linking/types.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// This reacts to backspace and interjects if it finds a custom mention pill
/// and deletes the entire node in that case
final CommandShortcutEvent backSpaceCommandForMentions = CommandShortcutEvent(
  key: 'backspace',
  getDescription: () => AppFlowyEditorL10n.current.cmdDeleteLeft,
  command: 'backspace, shift+backspace',
  handler: _backSpaceCommandHandlerForMentions,
);

CommandShortcutEventHandler _backSpaceCommandHandlerForMentions = (
  editorState,
) {
  final selection = editorState.selection;
  final selectionType = editorState.selectionType;

  if (selection == null ||
      (selectionType != null && selectionType != SelectionType.inline)) {
    // we let someone else deal with this
    return KeyEventResult.ignored;
  }

  final index = selection.startIndex;
  if (index == 0) {
    // nothing to deal with
    return KeyEventResult.ignored;
  }

  final selectedNode = editorState.getNodesInSelection(selection).firstOrNull;
  // what's the node before this?
  if (selectedNode == null || selectedNode.delta == null) {
    return KeyEventResult.ignored;
  }

  final lastInsert = selectedNode.delta?.last;

  if (lastInsert is TextInsert) {
    if (lastInsert.text.isEmpty) {
      // nothing to deal with
      return KeyEventResult.ignored;
    }

    final linkType = getMentionForInsert(lastInsert)?.type;
    if (linkType == LinkType.userId ||
        linkType == LinkType.roomId ||
        linkType == LinkType.spaceObject) {
      // we have a mention with a special pill, let's delete the entire node
      final transaction = editorState.transaction;
      // identify the entire size of the widget and remove it
      transaction.deleteText(
        selectedNode,
        selection.startIndex - lastInsert.text.length,
        lastInsert.text.length,
      );
      editorState.apply(transaction);
      return KeyEventResult.handled;
    }
  }
  return KeyEventResult.ignored;
};
