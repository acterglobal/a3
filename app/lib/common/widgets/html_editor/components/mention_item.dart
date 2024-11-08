import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MentionItem extends ConsumerWidget {
  const MentionItem({
    super.key,
    required this.userId,
    required this.displayName,
    required this.isSelected,
    required this.onTap,
  });

  final String userId;
  final String displayName;
  final bool isSelected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayName.isNotEmpty ? displayName : userId,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (displayName.isNotEmpty)
              Text(userId, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
