import 'package:flutter/material.dart';

class LastMessage extends StatelessWidget {
  final bool isUnread;
  final String message;
  final String? senderName;

  const LastMessage({
    super.key,
    this.isUnread = false,
    required this.message,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        isUnread ? theme.colorScheme.secondary : theme.colorScheme.surfaceTint;

    final text =
        senderName != null && message.isNotEmpty
            ? '$senderName: $message'
            : message;

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w300,
        color: textColor,
        fontSize: 13,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
