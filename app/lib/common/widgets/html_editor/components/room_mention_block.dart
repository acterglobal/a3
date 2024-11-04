import 'package:acter/common/widgets/html_editor/components/mention_content.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class RoomMentionBlock extends StatefulWidget {
  const RoomMentionBlock({
    super.key,
    required this.editorState,
    required this.roomId,
    required this.displayName,
    required this.blockId,
    required this.node,
    required this.textStyle,
    required this.index,
  });

  final EditorState editorState;
  final String roomId;
  final String? displayName;
  final String? blockId;
  final Node node;
  final TextStyle? textStyle;
  final int index;

  @override
  State<RoomMentionBlock> createState() => _RoomMentionBlockState();
}

class _RoomMentionBlockState extends State<RoomMentionBlock> {
  @override
  Widget build(BuildContext context) {
    final desktopPlatforms = [
      TargetPlatform.linux,
      TargetPlatform.macOS,
      TargetPlatform.windows,
    ];

    final Widget content = desktopPlatforms.contains(Theme.of(context).platform)
        ? GestureDetector(
            onTap: _handleRoomTap,
            behavior: HitTestBehavior.opaque,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: MentionContentWidget(
                mentionId: widget.roomId,
                displayName: widget.displayName,
                textStyle: widget.textStyle,
                editorState: widget.editorState,
                node: widget.node,
                index: widget.index,
              ),
            ),
          )
        : GestureDetector(
            onTap: _handleRoomTap,
            behavior: HitTestBehavior.opaque,
            child: MentionContentWidget(
              mentionId: widget.roomId,
              displayName: widget.displayName,
              textStyle: widget.textStyle,
              editorState: widget.editorState,
              node: widget.node,
              index: widget.index,
            ),
          );
    return content;
  }

  void _handleRoomTap() async {}
}
