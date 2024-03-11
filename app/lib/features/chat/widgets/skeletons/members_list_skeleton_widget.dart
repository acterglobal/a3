import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MembersListSkeleton extends StatelessWidget {
  const MembersListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(child: _buildSkeletonUI());
  }

  Widget _buildSkeletonUI() {
    return Column(
      children: [
        _buildMemberItemSkeletonUI(),
        _buildMemberItemSkeletonUI(),
        _buildMemberItemSkeletonUI(),
      ],
    );
  }

  Widget _buildMemberItemSkeletonUI() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            height: 70,
            width: 70,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Member title data'),
                Text('Member Descriptions data'),
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
