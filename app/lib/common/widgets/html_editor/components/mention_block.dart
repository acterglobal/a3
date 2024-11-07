import 'package:acter/common/widgets/html_editor/components/mention_content.dart';
import 'package:acter/common/widgets/html_editor/models/mention_block_keys.dart';
import 'package:acter/common/widgets/html_editor/models/mention_type.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class MentionBlock extends StatelessWidget {
  const MentionBlock({
    super.key,
    required this.editorState,
    required this.mention,
    required this.node,
    required this.index,
    required this.textStyle,
  });

  final EditorState editorState;
  final Map<String, dynamic> mention;
  final Node node;
  final int index;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final type = MentionType.fromStr(mention[MentionBlockKeys.type]);

    switch (type) {
      case MentionType.user:
        final String? userId = mention[MentionBlockKeys.userId] as String?;
        final String? blockId = mention[MentionBlockKeys.blockId] as String?;
        final String? displayName =
            mention[MentionBlockKeys.displayName] as String?;

        if (userId == null) {
          return const SizedBox.shrink();
        }

        return _mentionContent(
          context: context,
          mentionId: userId,
          blockId: blockId,
          editorState: editorState,
          displayName: displayName,
          node: node,
          index: index,
        );
      case MentionType.room:
        final String? roomId = mention[MentionBlockKeys.roomId] as String?;
        final String? blockId = mention[MentionBlockKeys.blockId] as String?;
        final String? displayName =
            mention[MentionBlockKeys.displayName] as String?;

        if (roomId == null) {
          return const SizedBox.shrink();
        }

        return _mentionContent(
          context: context,
          mentionId: roomId,
          blockId: blockId,
          editorState: editorState,
          displayName: displayName,
          node: node,
          index: index,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _mentionContent({
    required BuildContext context,
    required EditorState editorState,
    required String mentionId,
    String? blockId,
    required String? displayName,
    TextStyle? textStyle,
    required Node node,
    required int index,
  }) {
    final desktopPlatforms = [
      TargetPlatform.linux,
      TargetPlatform.macOS,
      TargetPlatform.windows,
    ];
    final mentionContentWidget = MentionContentWidget(
      mentionId: mentionId,
      displayName: displayName,
      textStyle: textStyle,
      editorState: editorState,
      node: node,
      index: index,
    );

    final Widget content = GestureDetector(
      onTap: _handleUserTap,
      behavior: HitTestBehavior.opaque,
      child: desktopPlatforms.contains(Theme.of(context).platform)
          ? MouseRegion(
              cursor: SystemMouseCursors.click,
              child: mentionContentWidget,
            )
          : mentionContentWidget,
    );

    return content;
  }

  void _handleUserTap() {
    // Implement user tap action (e.g., show profile, start chat)
  }
}
