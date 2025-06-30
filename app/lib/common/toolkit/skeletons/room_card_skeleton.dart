import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class RoomCardSkeleton extends StatelessWidget {
  const RoomCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: ListTile(
          leading: Bone.square(size: 48),
          title: Text('Room Card Skeleton'),
        ),
      ),
    );
  }
}
