import 'package:acter/features/space/widgets/about_card.dart';
import 'package:acter/features/space/widgets/links_card.dart';
import 'package:acter/features/space/widgets/chats_card.dart';
import 'package:acter/features/space/widgets/spaces_card.dart';
import 'package:acter/features/space/widgets/events_card.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpaceOverview extends ConsumerWidget {
  final String spaceIdOrAlias;
  const SpaceOverview({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // get platform of context.
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            EventsCard(spaceId: spaceIdOrAlias),
            AboutCard(spaceId: spaceIdOrAlias),
            LinksCard(spaceId: spaceIdOrAlias),
            ChatsCard(spaceId: spaceIdOrAlias),
            SpacesCard(spaceId: spaceIdOrAlias),
          ],
        ),
        // Row(
        //   children: [
        //     Column(
        //       children: [

        //       ],
        //     ),
        //     Column(
        //       children: [Text('placeholder')],
        //     ),
        //   ],
        // ),
      ),
    );
  }
}
