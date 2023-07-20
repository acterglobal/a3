import 'dart:core';
import 'dart:math';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:acter/common/utils/routes.dart';

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
          ...spaces.when(
            data: (spaces) {
              final widthCount =
                  (MediaQuery.of(context).size.width ~/ 600).toInt();
              const int minCount = 2;
              // we have more than just the spaces screen, put them into a grid.
              final List<Widget> items = [];
              bool checkPermission(String permission) {
                if (spaces.membership != null) {
                  return spaces.membership!.canString(permission);
                }
                return false;
              }

              final canLinkSpace = checkPermission('CanLinkSpaces');

              if (spaces.parents.isNotEmpty || spaces.mainParent != null) {
                List<Widget> children = [
                  const Expanded(child: Text('Parents'))
                ];
                if (checkPermission('CanSetParentSpace')) {
                  children.add(
                    PopupMenuButton(
                      icon: Icon(
                        Atlas.plus_circle,
                        color: Theme.of(context).colorScheme.neutral5,
                      ),
                      iconSize: 28,
                      color: Theme.of(context).colorScheme.surface,
                      itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                        PopupMenuItem(
                          onTap: () => customMsgSnackbar(
                            context,
                            'Create parent space feature isn\'t implemented yet',
                          ),
                          child: Row(
                            children: const <Widget>[
                              Text('Create Parent Space'),
                              Spacer(),
                              Icon(Atlas.connection),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () => customMsgSnackbar(
                            context,
                            'Link space feature isn\'t implemented yet',
                          ),
                          child: Row(
                            children: const <Widget>[
                              Text('Link Space as Parent'),
                              Spacer(),
                              Icon(Atlas.link_chain_thin),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                items.add(
                  SliverToBoxAdapter(
                    child: Row(
                      children: children,
                    ),
                  ),
                );
              }

              if (spaces.mainParent != null) {
                final space = spaces.mainParent!;
                items.add(
                  SliverToBoxAdapter(
                    child: ChildItem(key: Key(space.roomId), space: space),
                  ),
                );
              }
              if (spaces.parents.isNotEmpty) {
                if (spaces.parents.isNotEmpty) {
                  items.add(
                    SliverGrid.builder(
                      itemCount: spaces.parents.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: max(1, min(widthCount, minCount)),
                        childAspectRatio: 4,
                      ),
                      itemBuilder: (context, index) {
                        final space = spaces.parents[index];
                        return ChildItem(key: Key(space.roomId), space: space);
                      },
                    ),
                  );
                }
              }

              if (spaces.children.isNotEmpty || canLinkSpace) {
                List<Widget> children = [
                  const Expanded(child: Text('Subspaces'))
                ];
                if (canLinkSpace) {
                  children.add(
                    PopupMenuButton(
                      icon: Icon(
                        Atlas.plus_circle,
                        color: Theme.of(context).colorScheme.neutral5,
                      ),
                      iconSize: 28,
                      color: Theme.of(context).colorScheme.surface,
                      itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                        PopupMenuItem(
                          onTap: () => context.pushNamed(
                            Routes.createSpace.name,
                            queryParameters: {'parentSpaceId': spaceIdOrAlias},
                          ),
                          child: Row(
                            children: const <Widget>[
                              Text('Create Subspace'),
                              Spacer(),
                              Icon(Atlas.connection),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () => customMsgSnackbar(
                            context,
                            'Link space feature isn\'t implemented yet',
                          ),
                          child: Row(
                            children: const <Widget>[
                              Text('Add existing Space'),
                              Spacer(),
                              Icon(Atlas.link_chain_thin),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                items.add(
                  SliverToBoxAdapter(
                    child: Row(
                      children: children,
                    ),
                  ),
                );
              }

              if (spaces.children.isNotEmpty) {
                items.add(
                  SliverGrid.builder(
                    itemCount: spaces.children.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: max(1, min(widthCount, minCount)),
                      childAspectRatio: 4,
                    ),
                    itemBuilder: (context, index) {
                      final space = spaces.children[index];
                      return ChildItem(key: Key(space.roomId), space: space);
                    },
                  ),
                );
              }

              if (spaces.otherRelations.isNotEmpty || canLinkSpace) {
                List<Widget> children = [
                  const Expanded(child: Text('Recommended Spaces'))
                ];
                if (canLinkSpace) {
                  children.add(
                    IconButton(
                      icon: Icon(
                        Atlas.link_chain_thin,
                        color: Theme.of(context).colorScheme.neutral5,
                      ),
                      iconSize: 28,
                      color: Theme.of(context).colorScheme.surface,
                      onPressed: () => customMsgSnackbar(
                        context,
                        'Link space feature isn\'t implemented yet',
                      ),
                    ),
                  );
                }
                items.add(
                  SliverToBoxAdapter(
                    child: Row(
                      children: children,
                    ),
                  ),
                );
              }
              if (spaces.otherRelations.isNotEmpty) {
                items.add(
                  SliverGrid.builder(
                    itemCount: spaces.otherRelations.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: max(1, min(widthCount, minCount)),
                      childAspectRatio: 4,
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
                child: Center(
                  child: Text('Loading failed: $error'),
                ),
              )
            ],
            loading: () => [
              const SliverToBoxAdapter(
                child: Center(
                  child: Text('Loading'),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
