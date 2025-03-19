import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SpaceDetailsSkeletons extends StatelessWidget {
  const SpaceDetailsSkeletons({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBar(backgroundColor: Colors.transparent),
          Skeletonizer(child: spaceHeaderProfile()),
          Row(children: [menuItem(), menuItem(), menuItem()]),
          Skeletonizer(child: sections()),
          Skeletonizer(child: sections()),
          Skeletonizer(child: sections()),
        ],
      ),
    );
  }

  Widget spaceHeaderProfile() {
    return const Skeletonizer(
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Card(child: SizedBox(height: 70, width: 70)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(child: Text('Space Name')),
                SizedBox(child: Text('Space Visibility')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget menuItem() {
    return const Skeletonizer(
      child: Padding(padding: EdgeInsets.all(14), child: Text('Menu Item')),
    );
  }

  Widget sections() {
    return const Skeletonizer(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Text(
            'About descriptions About descriptions About descriptions About descriptions About descriptions About descriptions',
          ),
        ),
      ),
    );
  }
}
