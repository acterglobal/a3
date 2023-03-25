import 'package:acter/features/space/widgets/about_card.dart';
import 'package:acter/features/space/widgets/links_card.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpaceOverview extends ConsumerStatefulWidget {
  final String spaceIdOrAlias;
  const SpaceOverview({super.key, required this.spaceIdOrAlias});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SpaceOverviewState();
}

class _SpaceOverviewState extends ConsumerState<SpaceOverview> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // get platform of context.
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        AboutCard(spaceId: widget.spaceIdOrAlias),
        LinksCard(spaceId: widget.spaceIdOrAlias),
      ]),
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
    );
  }
}
