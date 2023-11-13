import 'dart:math';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/space/pages/shell_page.dart';
import 'package:acter/features/space/widgets/about_card.dart';
import 'package:acter/features/space/widgets/chats_card.dart';
import 'package:acter/features/space/widgets/events_card.dart';
import 'package:acter/features/space/widgets/links_card.dart';
import 'package:acter/features/space/widgets/non_acter_space_card.dart';
import 'package:acter/features/space/widgets/related_spaces_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ActerSpaceChecker extends ConsumerWidget {
  final Widget child;
  final String spaceId;
  final bool Function(ActerAppSettings?)? expectation;

  const ActerSpaceChecker({
    super.key,
    this.expectation,
    required this.spaceId,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(acterAppSettingsProvider(spaceId));
    final expCheck = expectation ?? (a) => a != null;
    return appSettings.when(
      data: (data) => expCheck(data) ? child : const SizedBox.shrink(),
      error: (error, stackTrace) => Text('Failed to load space: $error'),
      loading: () => const SizedBox.shrink(),
    );
  }
}

class SpaceOverview extends ConsumerWidget {
  final String spaceIdOrAlias;

  const SpaceOverview({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widthCount = (MediaQuery.of(context).size.width ~/ 300).toInt();
    const int minCount = 2;
    // get platform of context.
    return SingleChildScrollView(
      child: Column(
        children: [
          SpaceShell(spaceIdOrAlias: spaceIdOrAlias),
          StaggeredGrid.count(
            axisDirection: AxisDirection.down,
            crossAxisCount: min(widthCount, minCount),
            children: <Widget>[
              AboutCard(spaceId: spaceIdOrAlias),
              ActerSpaceChecker(
                spaceId: spaceIdOrAlias,
                expectation: (a) => a == null,
                child: NonActerSpaceCard(spaceId: spaceIdOrAlias),
              ),
              ActerSpaceChecker(
                spaceId: spaceIdOrAlias,
                expectation: (a) => a != null ? a.events().active() : false,
                child: EventsCard(spaceId: spaceIdOrAlias),
              ),
              ActerSpaceChecker(
                spaceId: spaceIdOrAlias,
                expectation: (a) => a != null ? a.pins().active() : false,
                child: LinksCard(spaceId: spaceIdOrAlias),
              ),
              ChatsCard(spaceId: spaceIdOrAlias),
              RelatedSpacesCard(spaceId: spaceIdOrAlias),
            ],
          ),
        ],
      ),
    );
  }
}
