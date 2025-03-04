import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:acter/l10n/generated/l10n.dart';

class ActionItemSkeleton extends StatelessWidget {
  final IconData iconData;
  final String? actionName;

  const ActionItemSkeleton({
    super.key,
    this.iconData = Icons.add,
    this.actionName,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(child: _buildActionItemSkeletonUI(context));
  }

  Widget _buildActionItemSkeletonUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(iconData),
          const SizedBox(height: 10),
          Text(actionName ?? L10n.of(context).actionName),
        ],
      ),
    );
  }
}
