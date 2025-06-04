import 'dart:math';

import 'package:acter/common/toolkit/html_editor/mentions/components/mention_list.dart';
import 'package:acter/common/toolkit/html_editor/services/constants.dart';
import 'package:acter/features/chat_ng/globals.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

OverlayEntry? _menuEntry;

class MentionMenu {
  MentionMenu({
    required this.context,
    required this.editorState,
    required this.roomId,
    required this.mentionTrigger,
  });

  final BuildContext context;
  final EditorState editorState;
  final String roomId;
  final String mentionTrigger;

  bool selectionChangedByMenu = false;

  static void dismissAll() {
    _menuEntry?.remove();
    _menuEntry = null;
  }

  static bool isShowing() => _menuEntry != null;

  static void dismiss() {
    _menuEntry?.remove();
    _menuEntry = null;
  }

  void show() {
    if (_menuEntry != null) return;
    _show();
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
    final Widget listWidget = switch (mentionTrigger) {
      userMentionChar => UserMentionList(
        editorState: editorState,
        onDismiss: dismiss,
        onShow: show,
        roomId: roomId,
      ),
      roomMentionChar => RoomMentionList(
        editorState: editorState,
        onDismiss: dismiss,
        onShow: show,
        roomId: roomId,
      ),
      _ => const SizedBox.shrink(),
    };

    final menuEntry =
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

    Overlay.of(context).insert(menuEntry);
  }
}
