import 'package:flutter/material.dart';

class LastMessage extends StatelessWidget {
  final String message;
  final String? senderName;

  const LastMessage({
    super.key,
    required this.message,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.surfaceTint;

    final text = senderName != null ? '$senderName: $message' : message;

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(color: textColor),
    );
  }
}
