import 'dart:math';

import 'package:acter/features/home/widgets/my_spaces_section.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // return Center(child: Text('Dashboard - replace me'));
    return Column(
      children: const [
        MySpacesSection(),
      ],
    );
    // final widthCount = (MediaQuery.of(context).size.width ~/ 280).toInt();

    // const int minCount = 2;
    // get platform of context.
    // return SingleChildScrollView(
    //   physics: const NeverScrollableScrollPhysics(),
    //   child: Container(
    //     margin: const EdgeInsets.all(20),
    //     child: StaggeredGrid.count(
    //       axisDirection: AxisDirection.down,
    //       crossAxisCount: min(widthCount, minCount),
    //       children: const <Widget>[
    //         MySpacesSection(),
    //         MySpacesSection(),
    //         // AboutCard(spaceId: spaceIdOrAlias),
    //         // EventsCard(spaceId: spaceIdOrAlias),
    //         // LinksCard(spaceId: spaceIdOrAlias),
    //         // ChatsCard(spaceId: spaceIdOrAlias),
    //         // SpacesCard(spaceId: spaceIdOrAlias),
    //       ],
    //     ),
    //     // Row(
    //     //   children: [
    //     //     Column(
    //     //       children: [

    //     //       ],
    //     //     ),
    //     //     Column(
    //     //       children: [Text('placeholder')],
    //     //     ),
    //     //   ],
    //     // ),
    //   ),
    // );
  }
}
