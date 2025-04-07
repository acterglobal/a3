import 'package:flutter/material.dart';

class UnreadCount extends StatelessWidget {
  final int? count;

  const UnreadCount({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == null || count == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        count.toString(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface,
          fontSize: 13,
        ),
      ),
    );
  }
}
