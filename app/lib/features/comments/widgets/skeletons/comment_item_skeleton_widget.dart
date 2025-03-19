import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:acter/l10n/generated/l10n.dart';

class CommentItemSkeleton extends StatelessWidget {
  const CommentItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(child: _buildEventItemSkeletonUI(context));
  }

  Widget _buildEventItemSkeletonUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(height: 50, width: 50, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(L10n.of(context).commentEmptyStateTitle)],
            ),
          ),
        ],
      ),
    );
  }
}
