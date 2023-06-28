import 'dart:core';
import 'dart:math';

import 'package:acter/features/space/providers/space_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/space/widgets/top_nav.dart';
import 'package:go_router/go_router.dart';

class ChildItem extends StatelessWidget {
  final SpaceItem space;
  const ChildItem({Key? key, required this.space}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final profile = space.spaceProfileData;
    final roomId = space.roomId;
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.inversePrimary,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      color: Theme.of(context).colorScheme.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        onTap: () => context.go('/$roomId'),
        title: Text(
          profile.displayName ?? roomId,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        leading: ActerAvatar(
          mode: DisplayMode.Space,
          displayName: profile.displayName,
          uniqueId: roomId,
          avatar: profile.getAvatarImage(),
          size: 48,
        ),
        trailing: const Icon(Icons.more_vert),
      ),
    );
  }
}

class RelatedSpacesPage extends ConsumerWidget {
  final String spaceIdOrAlias;
  const RelatedSpacesPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(relatedSpaceItemsProvider(spaceIdOrAlias));
    // get platform of context.
    return Padding(
      padding: const EdgeInsets.all(20),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: TopNavBar(
              spaceId: spaceIdOrAlias,
              key: Key('$spaceIdOrAlias::topnav'),
              selectedKey: const Key('spaces'),
            ),
          ),
          ...spaces.when(
            data: (spaces) {
              final widthCount =
                  (MediaQuery.of(context).size.width ~/ 600).toInt();
              const int minCount = 2;
              // we have more than just the spaces screen, put them into a grid.
              final List<Widget> items = [];
              if (spaces.mainParent != null) {
                final space = spaces.mainParent!;
                items.add(const SliverToBoxAdapter(child: Text('Parent')));
                items.add(
                  SliverToBoxAdapter(
                    child: ChildItem(key: Key(space.roomId), space: space),
                  ),
                );
              }
              if (spaces.parents.isNotEmpty) {
                if (items.isEmpty) {
                  items.add(const SliverToBoxAdapter(child: Text('Parents')));
                }
                items.add(
                  SliverGrid.builder(
                    itemCount: spaces.parents.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: max(1, min(widthCount, minCount)),
                      childAspectRatio: 6,
                    ),
                    itemBuilder: (context, index) {
                      final space = spaces.parents[index];
                      return ChildItem(key: Key(space.roomId), space: space);
                    },
                  ),
                );
              }
              if (spaces.children.isNotEmpty) {
                items.add(const SliverToBoxAdapter(child: Text('Subspaces')));
                items.add(
                  SliverGrid.builder(
                    itemCount: spaces.children.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: max(1, min(widthCount, minCount)),
                      childAspectRatio: 6,
                    ),
                    itemBuilder: (context, index) {
                      final space = spaces.children[index];
                      return ChildItem(key: Key(space.roomId), space: space);
                    },
                  ),
                );
              }
              if (spaces.otherRelations.isNotEmpty) {
                items.add(
                  const SliverToBoxAdapter(child: Text('Related Spaces')),
                );
                items.add(
                  SliverGrid.builder(
                    itemCount: spaces.otherRelations.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: max(1, min(widthCount, minCount)),
                      childAspectRatio: 6,
                    ),
                    itemBuilder: (context, index) {
                      final space = spaces.otherRelations[index];
                      return ChildItem(key: Key(space.roomId), space: space);
                    },
                  ),
                );
              }

              if (items.isEmpty) {
                // FIXME: show something neat here
              }

              return items;
            },
            error: (error, stack) => [
              SliverToBoxAdapter(
                child: Text('Loading failed: $error'),
              )
            ],
            loading: () => [
              const SliverToBoxAdapter(
                child: Text('Loading'),
              )
            ],
          ),
        ],
      ),
    );
  }
}
