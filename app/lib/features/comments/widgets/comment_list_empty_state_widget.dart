import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class CommentListEmptyStateWidget extends StatelessWidget {
  final bool useCompactView;

  const CommentListEmptyStateWidget({super.key, this.useCompactView = true});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).unselectedWidgetColor;
    return useCompactView
        ? compactEmptyState(context, color)
        : fullViewEmptyState(context, color);
  }

  Widget fullViewEmptyState(BuildContext context, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Atlas.chats, color: color, size: 52),
        const SizedBox(height: 16),
        Text(
          L10n.of(context).commentEmptyStateTitle,
          style:
              Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
        ),
        Text(
          L10n.of(context).commentEmptyStateAction,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
        ),
      ],
    );
  }

  Widget compactEmptyState(BuildContext context, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Atlas.chats, color: color, size: 40),
          const SizedBox(width: 16),
          Column(
            children: [
              Text(
                L10n.of(context).commentEmptyStateTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: color),
              ),
              Text(
                L10n.of(context).commentEmptyStateAction,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
