import 'package:acter/common/widgets/emoji_picker_widget.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatEmojiPicker extends ConsumerWidget {
  final EditorState editorState;
  const ChatEmojiPicker({super.key, required this.editorState});

  // editor picker widget backspace handling
  void handleBackspacePressed(WidgetRef ref) {
    final isEmpty = editorState.transaction.document.isEmpty;
    if (isEmpty) {
      // nothing left to clear, close the emoji picker
      ref.read(chatInputProvider.notifier).emojiPickerVisible(false);
      return;
    }
    if (!editorState.document.isEmpty) {
      editorState.deleteBackward();
    }
  }

  // select emoji handler for editor state
  void handleEmojiSelected(Category? category, Emoji emoji) {
    final selection = editorState.selection;
    final transaction = editorState.transaction;
    if (selection != null) {
      if (selection.isCollapsed) {
        final node = editorState.getNodeAtPath(selection.end.path);
        if (node == null) return;
        // we're at the start
        transaction.insertText(node, selection.endIndex, emoji.emoji);
        transaction.afterSelection = Selection.collapsed(
          Position(
            path: selection.end.path,
            offset: selection.end.offset + emoji.emoji.length,
          ),
        );
      } else {
        // we have selected some text part to replace with emoji
        final startNode = editorState.getNodeAtPath(selection.start.path);
        if (startNode == null) return;
        transaction.deleteText(
          startNode,
          selection.startIndex,
          selection.end.offset - selection.start.offset,
        );
        transaction.insertText(startNode, selection.startIndex, emoji.emoji);

        transaction.afterSelection = Selection.collapsed(
          Position(
            path: selection.start.path,
            offset: selection.start.offset + emoji.emoji.length,
          ),
        );
      }

      editorState.apply(transaction);
    }
    return;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.sizeOf(context);
    return EmojiPickerWidget(
      size: Size(screenSize.width, screenSize.height * 0.3),
      onEmojiSelected: handleEmojiSelected,
      onBackspacePressed: () => handleBackspacePressed(ref),
      onClosePicker:
          () => ref.read(chatInputProvider.notifier).emojiPickerVisible(false),
    );
  }
}
