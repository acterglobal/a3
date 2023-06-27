import 'dart:math';

import 'package:acter/features/space/widgets/about_card.dart';
import 'package:acter/features/space/widgets/chats_card.dart';
import 'package:acter/features/space/widgets/events_card.dart';
import 'package:acter/features/space/widgets/links_card.dart';
import 'package:acter/features/space/widgets/related_spaces_card.dart';
import 'package:acter/features/space/widgets/top_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class SpaceOverview extends ConsumerWidget {
  final String spaceIdOrAlias;
  const SpaceOverview({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widthCount = (MediaQuery.of(context).size.width ~/ 300).toInt();
    const int minCount = 2;
    // get platform of context.
    return Column(
      children: [
        TopNavBar(
          spaceId: spaceIdOrAlias,
          key: Key('$spaceIdOrAlias::topnav'),
          selectedKey: const Key('overview'),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: StaggeredGrid.count(
            axisDirection: AxisDirection.down,
            crossAxisCount: min(widthCount, minCount),
            children: <Widget>[
              AboutCard(spaceId: spaceIdOrAlias),
              EventsCard(spaceId: spaceIdOrAlias),
              LinksCard(spaceId: spaceIdOrAlias),
              ChatsCard(spaceId: spaceIdOrAlias),
              RelatedSpacesCard(spaceId: spaceIdOrAlias),
            ],
          ),
        )
      ],
    );
  }
}
