import 'dart:math';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/features/spaces/model/keys.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpacesPage extends ConsumerStatefulWidget {
  const SpacesPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SpacesPageState();
}

class _SpacesPageState extends ConsumerState<SpacesPage> {
  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          PageHeaderWidget(
            centerTitle: true,
            expandedHeight: 0,
            actions: [
              PopupMenuButton(
                key: SpacesKeys.mainActions,
                icon: const Icon(Atlas.plus_circle),
                iconSize: 28,
                color: Theme.of(context).colorScheme.surface,
                itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                  PopupMenuItem(
                    key: SpacesKeys.actionCreate,
                    onTap: () => context.pushNamed(Routes.createSpace.name),
                    child: Row(
                      children: <Widget>[
                        Text(lang.createSpace),
                        const Spacer(),
                        const Icon(Atlas.connection),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () {
                      context.pushNamed(Routes.searchPublicDirectory.name);
                    },
                    child: Row(
                      children: <Widget>[
                        Text(lang.joinSpace),
                        const Spacer(),
                        const Icon(Atlas.calendar_dots),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            title: lang.spaces,
          ),
          renderSpaceList(context),
        ],
      ),
    );
  }

  SliverGrid renderSpaceList(BuildContext context) {
    // we have more than just the spaces screen, put them into a grid.
    final bookmarked = ref.watch(bookmarkedSpacesProvider);
    final others = ref.watch(unbookmarkedSpacesProvider);
    final widthCount = (MediaQuery.of(context).size.width ~/ 300).toInt();
    const int minCount = 3;

    return SliverGrid.builder(
      itemCount: bookmarked.length + others.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: max(1, min(widthCount, minCount)),
        mainAxisExtent: 100,
        childAspectRatio: 4,
      ),
      itemBuilder: (context, index) {
        String roomId = index < bookmarked.length
            ? bookmarked[index].getRoomIdStr()
            : others[index - bookmarked.length].getRoomIdStr();
        return RoomCard(
          onTap: () => context.pushNamed(
            Routes.space.name,
            pathParameters: {'spaceId': roomId},
          ),
          key: Key('space-list-item-$roomId'),
          roomId: roomId,
        );
      },
    );
  }
}
