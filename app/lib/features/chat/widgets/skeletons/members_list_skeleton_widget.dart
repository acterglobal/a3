import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MembersListSkeleton extends StatelessWidget {
  const MembersListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(child: _buildSkeletonUI(context));
  }

  Widget _buildSkeletonUI(BuildContext context) {
    return Column(
      children: [
        _buildMemberItemSkeletonUI(context),
        _buildMemberItemSkeletonUI(context),
        _buildMemberItemSkeletonUI(context),
      ],
    );
  }

  Widget _buildMemberItemSkeletonUI(BuildContext context) {
    final lang = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(height: 70, width: 70, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.memberTitleData),
                Text(lang.memberDescriptionsData),
              ],
            ),
          ),
          const SizedBox(width: 20),
          const Icon(Atlas.crown_winner_thin),
          const SizedBox(width: 10),
          const Icon(Atlas.dots_vertical),
        ],
      ),
    );
  }
}
