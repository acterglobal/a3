import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ActionItemSkeleton extends StatelessWidget {
  final IconData iconData;
  final String actionName;

  const ActionItemSkeleton({
    super.key,
    this.iconData = Icons.add,
    this.actionName = 'Action name',
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(child: _buildActionItemSkeletonUI());
  }

  Widget _buildActionItemSkeletonUI() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(iconData),
          const SizedBox(height: 10),
          Text(actionName),
        ],
      ),
    );
  }
}
