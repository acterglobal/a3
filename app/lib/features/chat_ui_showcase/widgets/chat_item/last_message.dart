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
        isUnread ? theme.colorScheme.onSurface : theme.colorScheme.surfaceTint;

    return Row(
      children: [
        if (senderName != null)
          Text(
            '$senderName : ',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: textColor,
              fontSize: 14,
            ),
          ),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w400,
              color: textColor,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
