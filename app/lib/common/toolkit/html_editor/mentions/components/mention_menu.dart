import 'dart:math';

import 'package:acter/common/toolkit/html_editor/mentions/components/mention_list.dart';
import 'package:acter/common/toolkit/html_editor/mentions/models/mention_type.dart';
import 'package:acter/common/toolkit/html_editor/mentions/selected_mention_provider.dart';
import 'package:acter/common/toolkit/html_editor/services/constants.dart';
import 'package:acter/features/chat_ng/globals.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

MentionMenu? _menu;

class MentionMenu {
  MentionMenu({
    required this.context,
    required this.editorState,
    required this.roomId,
    required this.mentionType,
    required this.ref,
  });

  final BuildContext context;
  final EditorState editorState;
  final String roomId;
  final MentionType mentionType;
  final WidgetRef ref;
  OverlayEntry? _menuEntry;

  bool selectionChangedByMenu = false;

  static bool isShowing() => _menu != null;

  static void dismiss() {
    _menu?._menuEntry?.remove();
    _menu = null;
  }

  void show() {
    if (_menu != null) return;
    _show();
  }

  // control functions
  static void next() {
    _menu?.provider.next();
  }

  static void prev() {
    _menu?.provider.prev();
  }

  static void selectCurrent() {
    _menu?._selectCurrent();
  }

  void _selectCurrent() {
    final client = _menu;
    if (client == null) return;
    final filtered = switch (client.mentionType) {
      MentionType.user => ref.read(filteredUserSuggestionsProvider(roomId)),
      MentionType.room => ref.read(filteredRoomSuggestionsProvider(roomId)),
    };
    final selected = switch (client.mentionType) {
      MentionType.user => ref.read(selecteUserMentionProvider(roomId)),
      MentionType.room => ref.read(selectedRoomMentionProvider(roomId)),
    };
    if (selected == null) return;
    final item = filtered.keys.elementAt(selected);
    client._select(client.mentionType, item, filtered[item]);
  }

  SelectedMentionNotifier get provider => switch (mentionType) {
    MentionType.user => ref.read(selecteUserMentionProvider(roomId).notifier),
    MentionType.room => ref.read(selectedRoomMentionProvider(roomId).notifier),
  };

  String _makeUri(MentionType type, String id) => switch (type) {
    MentionType.user => 'matrix:u/${id.substring(1)}',
    MentionType.room => 'matrix:roomid/$id',
  };

  void _select(MentionType type, String id, String? displayName) {
    final selection = editorState.selection;
    if (selection == null) return;

    final transaction = editorState.transaction;
    final node = editorState.getNodeAtPath(selection.end.path);
    if (node == null) return;

    final text = node.delta?.toPlainText() ?? '';
    final cursorPosition = selection.end.offset;

    // Find the trigger symbol position by searching backwards from cursor
    int atSymbolPosition = -1;
    final mentionTriggers = [userMentionChar, roomMentionChar];
    for (int i = cursorPosition - 1; i >= 0; i--) {
      if (mentionTriggers.contains(text[i])) {
        atSymbolPosition = i;
        break;
      }
    }

    if (atSymbolPosition == -1) return; // No trigger found
    final lengthToReplace = cursorPosition - atSymbolPosition;
    final replacementText = displayName ?? id;

    transaction.replaceText(
      // remove the trigger and content
      node,
      atSymbolPosition,
      lengthToReplace,
      replacementText,
      attributes: {'href': _makeUri(type, id), 'inline': true},
    );

    editorState.apply(transaction);
    MentionMenu.dismiss();
  }

  void _show() {
    // Get position of editor field
    final RenderBox? editorBox =
        chatEditorKey.currentContext?.findRenderObject() as RenderBox?;
    if (editorBox == null) return;

    final editorPosition = editorBox.localToGlobal(Offset.zero);
    final maxHeight = max(300, MediaQuery.sizeOf(context).height * 0.5);
    final isWide = MediaQuery.sizeOf(context).width > 600;

    final bottom = editorPosition.dy - 4;

    // render based on mention type
    final Widget listWidget = switch (mentionType) {
      MentionType.user => UserMentionList(
        editorState: editorState,
        onDismiss: dismiss,
        onShow: show,
        roomId: roomId,
        onSelected: _select,
      ),
      MentionType.room => RoomMentionList(
        editorState: editorState,
        onDismiss: dismiss,
        onShow: show,
        roomId: roomId,
        onSelected: _select,
      ),
    };
    _menuEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: max(0, bottom - maxHeight),
            height: maxHeight.toDouble(),
            left: isWide ? editorPosition.dx : 12,
            right: isWide ? editorPosition.dx : 12,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: TapRegion(
                behavior: HitTestBehavior.opaque,
                onTapOutside: (event) => dismiss(),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: maxHeight.toDouble(),
                    ),
                    padding: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: listWidget,
                  ),
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(_menuEntry!);
  }
}
