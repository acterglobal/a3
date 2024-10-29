import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class MentionContentWidget extends StatelessWidget {
  const MentionContentWidget({
    super.key,
    required this.mentionId,
    this.displayName,
    required this.textStyle,
    required this.editorState,
    required this.node,
    required this.index,
  });

  final String mentionId;
  final String? displayName;
  final TextStyle? textStyle;
  final EditorState editorState;
  final Node node;
  final int index;

  @override
  Widget build(BuildContext context) {
    final baseTextStyle = textStyle?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      leadingDistribution: TextLeadingDistribution.even,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (displayName != null)
          Text(
            displayName!,
            style: baseTextStyle?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(width: 4),
        Text(
          mentionId,
          style: baseTextStyle?.copyWith(
            fontSize: (baseTextStyle.fontSize ?? 14.0) * 0.9,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }
}
