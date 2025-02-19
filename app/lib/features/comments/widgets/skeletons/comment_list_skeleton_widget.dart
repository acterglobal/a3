import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CommentListSkeletonWidget extends StatelessWidget {
  const CommentListSkeletonWidget({super.key});

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
      leading: Icon(Atlas.chats, size: 60),
      title: Text('Title Title Title Title Title'),
      subtitle: Text(
        'Sub-title Sub-title Sub-title Sub-title Sub-title Sub-title Sub-title',
      ),
    );
  }
}
