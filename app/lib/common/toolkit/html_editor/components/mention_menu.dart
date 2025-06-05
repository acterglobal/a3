import 'package:acter/common/toolkit/html_editor/components/mention_list.dart';
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

    final isLargeScreen = MediaQuery.sizeOf(context).width > 600;
    const chatInputHeight = 56.0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final menuBottom = bottomInset + chatInputHeight;

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
                left:
                    isLargeScreen
                        ? editorBox.localToGlobal(Offset.zero).dx
                        : 12,
                right:
                    isLargeScreen
                        ? editorBox.localToGlobal(Offset.zero).dx
                        : 12,
                bottom: menuBottom,
                child: Material(
                  elevation: 0,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
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
