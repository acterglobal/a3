import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/common/widgets/spaces/space_card.dart';
import 'package:acter/features/spaces/model/keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:go_router/go_router.dart';

import 'dart:math';

class SpacesPage extends ConsumerStatefulWidget {
  const SpacesPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SpacesPageState();
}

class _SpacesPageState extends ConsumerState<SpacesPage> {
  @override
  Widget build(BuildContext context) {
    final spaces = ref.watch(spacesProvider);
    final widthCount = (MediaQuery.of(context).size.width ~/ 600).toInt();
    const int minCount = 2;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: CustomScrollView(
          slivers: <Widget>[
            PageHeaderWidget(
              centerTitle: true,
              expandedHeight: 0,
              sectionDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              actions: <Widget>[
                PopupMenuButton(
                  key: SpacesKeys.mainActions,
                  icon: Icon(
                    Atlas.plus_circle,
                    color: Theme.of(context).colorScheme.neutral5,
                  ),
                  iconSize: 28,
                  color: Theme.of(context).colorScheme.surface,
                  itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                    PopupMenuItem(
                      key: SpacesKeys.actionCreate,
                      onTap: () => context.pushNamed(Routes.createSpace.name),
                      child: const Row(
                        children: <Widget>[
                          Text('Create Space'),
                          Spacer(),
                          Icon(Atlas.connection),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () => context.pushNamed(Routes.joinSpace.name),
                      child: const Row(
                        children: <Widget>[
                          Text('Join Space'),
                          Spacer(),
                          Icon(Atlas.calendar_dots),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              title: 'Spaces',
            ),
            // we have more than just the spaces screen, put them into a grid.
            SliverGrid.builder(
              itemCount: spaces.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: max(1, min(widthCount, minCount)),
                childAspectRatio: 4,
              ),
              itemBuilder: (context, index) {
                final space = spaces[index];
                final roomId = space.getRoomIdStr();
                return SpaceCard(
                  onTap: () => context.go('/$roomId'),
                  space: space,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
