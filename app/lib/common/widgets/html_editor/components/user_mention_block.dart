import 'package:acter/common/widgets/html_editor/components/mention_content.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class UserMentionBlock extends StatefulWidget {
  const UserMentionBlock({
    super.key,
    required this.editorState,
    required this.userId,
    required this.displayName,
    required this.blockId,
    required this.node,
    required this.textStyle,
    required this.index,
  });

  final EditorState editorState;
  final String userId;
  final String? displayName;
  final String? blockId;
  final Node node;
  final TextStyle? textStyle;
  final int index;

  @override
  State<UserMentionBlock> createState() => _UserMentionBlockState();
}

class _UserMentionBlockState extends State<UserMentionBlock> {
  @override
  Widget build(BuildContext context) {
    final desktopPlatforms = [
      TargetPlatform.linux,
      TargetPlatform.macOS,
      TargetPlatform.windows,
    ];

    final Widget content = desktopPlatforms.contains(Theme.of(context).platform)
        ? GestureDetector(
            onTap: _handleUserTap,
            behavior: HitTestBehavior.opaque,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: MentionContentWidget(
                mentionId: widget.userId,
                displayName: widget.displayName,
                textStyle: widget.textStyle,
                editorState: widget.editorState,
                node: widget.node,
                index: widget.index,
              ),
            ),
          )
        : GestureDetector(
            onTap: _handleUserTap,
            behavior: HitTestBehavior.opaque,
            child: MentionContentWidget(
              mentionId: widget.userId,
              displayName: widget.displayName,
              textStyle: widget.textStyle,
              editorState: widget.editorState,
              node: widget.node,
              index: widget.index,
            ),
          );
    return content;
  }

  void _handleUserTap() {
    // Implement user tap action (e.g., show profile, start chat)
  }
}
