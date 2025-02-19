import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class InviteListSkeleton extends StatelessWidget {
  const InviteListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView(
        shrinkWrap: true,
        children: [
          listItem(),
          listItem(),
          listItem(),
          listItem(),
          listItem(),
        ],
      ),
    );
  }

  Widget listItem() {
    return const ListTile(
      title: Text('Title Title Title Title Title'),
      subtitle: Text(
        'Sub-title Sub-title Sub-title Sub-title Sub-title Sub-title Sub-title',
      ),
    );
  }
}
