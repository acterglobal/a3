import 'package:acter/common/widgets/html_editor/components/mention_handler.dart';
import 'package:acter/common/widgets/html_editor/models/mention_type.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class MentionMenu {
  MentionMenu({
    required this.context,
    required this.editorState,
    required this.roomId,
    required this.style,
    required this.mentionType,
  });

  final BuildContext context;
  final EditorState editorState;
  final String roomId;
  final MentionMenuStyle style;
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
        left: position.dx - 20, // Align with left edge of input
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
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical, // Changed to vertical scrolling
                child: MentionHandler(
                  editorState: editorState,
                  roomId: roomId,
                  onDismiss: dismiss,
                  onSelectionUpdate: _onSelectionUpdate,
                  style: style,
                  mentionType: mentionType,
                ),
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

// Style configuration for mention menu
class MentionMenuStyle {
  const MentionMenuStyle({
    required this.backgroundColor,
    required this.textColor,
    required this.selectedColor,
    required this.selectedTextColor,
    required this.hintColor,
  });

  const MentionMenuStyle.light()
      : backgroundColor = Colors.white,
        textColor = const Color(0xFF333333),
        selectedColor = const Color(0xFFE0F8FF),
        selectedTextColor = const Color.fromARGB(255, 56, 91, 247),
        hintColor = const Color(0xFF555555);

  const MentionMenuStyle.dark()
      : backgroundColor = const Color(0xFF282E3A),
        textColor = const Color(0xFFBBC3CD),
        selectedColor = const Color(0xFF00BCF0),
        selectedTextColor = const Color(0xFF131720),
        hintColor = const Color(0xFFBBC3CD);

  final Color backgroundColor;
  final Color textColor;
  final Color selectedColor;
  final Color selectedTextColor;
  final Color hintColor;
}
