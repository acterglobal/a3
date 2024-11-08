import 'package:acter/common/widgets/html_editor/components/mention_list.dart';
import 'package:acter/common/widgets/html_editor/models/mention_type.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class MentionMenu {
  MentionMenu({
    required this.context,
    required this.editorState,
    required this.roomId,
    required this.mentionType,
  });

  final BuildContext context;
  final EditorState editorState;
  final String roomId;
  final MentionType mentionType;

  OverlayEntry? _menuEntry;
  bool selectionChangedByMenu = false;

  void dismiss() {
    if (_menuEntry != null) {
      editorState.service.keyboardService?.enable();
      editorState.service.scrollService?.enable();
      keepEditorFocusNotifier.decrease();
    }

    _menuEntry?.remove();
    _menuEntry = null;
  }

  void _onSelectionUpdate() => selectionChangedByMenu = true;

  void show() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _show());
  }

  void _show() {
    dismiss();

    // Get position of editor
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Size size = renderBox.size;
    final Offset position = renderBox.localToGlobal(Offset.zero);

    _menuEntry = OverlayEntry(
      builder: (context) => Positioned(
        // Position relative to input field
        left: position.dx + 20, // Align with left edge of input
        // Position above input with some padding
        bottom: 70,
        width: size.width, // Match input width
        child: Material(
          elevation: 8, // Add some elevation for better visibility
          borderRadius: BorderRadius.circular(8),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: dismiss,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 200, // Limit maximum height
                maxWidth: size.width, // Match input width
              ),
              child: MentionList(
                editorState: editorState,
                roomId: roomId,
                onDismiss: dismiss,
                onSelectionUpdate: _onSelectionUpdate,
                mentionType: mentionType,
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_menuEntry!);
    editorState.service.keyboardService?.disable(showCursor: true);
    editorState.service.scrollService?.disable();
  }
}
