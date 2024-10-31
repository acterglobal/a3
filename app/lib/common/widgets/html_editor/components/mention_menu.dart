import 'package:acter/common/widgets/html_editor/components/mention_block.dart';
import 'package:acter/common/widgets/html_editor/components/mention_handler.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

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

    _menuEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        bottom: 50,
        child: Material(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: dismiss,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
    );

    Overlay.of(context).insert(_menuEntry!);

    editorState.service.keyboardService?.disable(showCursor: true);
    editorState.service.scrollService?.disable();
  }
}
