import 'package:acter/common/toolkit/html_editor/mentions/components/mention_list.dart';
import 'package:acter/common/toolkit/html_editor/services/constants.dart';
import 'package:acter/features/chat_ng/globals.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

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

  OverlayEntry? _menuEntry;
  bool selectionChangedByMenu = false;
  static const menuHeight = 200.0;

  void dismiss() {
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
    final isLargeScreen = MediaQuery.sizeOf(context).width > 600;

    final top = editorPosition.dy - menuHeight - 4;

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

    _menuEntry = OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: dismiss,
                  child: Container(color: Colors.transparent),
                ),
              ),

              Positioned(
                top: top,
                left: isLargeScreen ? editorPosition.dx : 12,
                right: isLargeScreen ? editorPosition.dx : 12,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 12),
                    height: menuHeight,
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
            ],
          ),
    );

    Overlay.of(context).insert(_menuEntry!);
  }
}
