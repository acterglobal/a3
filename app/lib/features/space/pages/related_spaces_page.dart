import 'dart:core';
import 'dart:math';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/spaces/space_card.dart';
import 'package:acter/common/widgets/spaces/space_hierarchy_card.dart';
import 'package:acter/features/space/providers/notifiers/space_hierarchy_notifier.dart';
import 'package:acter/features/space/providers/space_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

class RelatedSpacesPage extends ConsumerWidget {
  final String spaceIdOrAlias;
  const RelatedSpacesPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spaceRelationsOverviewProvider(spaceIdOrAlias));
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
              void addSubspaceHeading(String title, bool withTools) {
                List<Widget> children = [Expanded(child: Text(title))];
                if (canLinkSpace && withTools) {
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
                          child: const Row(
                            children: <Widget>[
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
                          child: const Row(
                            children: <Widget>[
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

              if (spaces.parents.isNotEmpty || spaces.mainParent != null) {
                List<Widget> children = [
                  const Expanded(child: Text('Parents')),
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
                          child: const Row(
                            children: <Widget>[
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
                          child: const Row(
                            children: <Widget>[
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
                    child:
                        SpaceCard(key: Key(space.getRoomIdStr()), space: space),
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
                        return SpaceCard(
                          key: Key(space.getRoomIdStr()),
                          space: space,
                          showParent: false,
                        );
                      },
                    ),
                  );
                }
              }
              if (spaces.knownSubspaces.isNotEmpty) {
                if (spaces.hasMoreSubspaces) {
                  addSubspaceHeading('My Subspaces', false);
                } else {
                  addSubspaceHeading('Subspaces', true);
                }
                items.add(
                  SliverGrid.builder(
                    itemCount: spaces.knownSubspaces.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: max(1, min(widthCount, minCount)),
                      childAspectRatio: 4,
                    ),
                    itemBuilder: (context, index) {
                      final space = spaces.knownSubspaces[index];
                      return SpaceCard(
                        key: Key(space.getRoomIdStr()),
                        space: space,
                        showParent: false,
                      );
                    },
                  ),
                );
              }
              if (spaces.hasMoreSubspaces) {
                if (spaces.knownSubspaces.isEmpty) {
                  addSubspaceHeading('Subspaces', true);
                } else {
                  addSubspaceHeading('More Subspaces', true);
                }
                items.add(
                  RiverPagedBuilder<Next?, SpaceHierarchyRoomInfo>.autoDispose(
                    firstPageKey: const Next(isStart: true),
                    provider: remoteSpaceHierarchyProvider(spaces),
                    itemBuilder: (context, item, index) =>
                        SpaceHierarchyCard(space: item),
                    pagedBuilder: (controller, builder) => PagedSliverList(
                      pagingController: controller,
                      builderDelegate: builder,
                    ),
                  ),
                );
              }

              if (spaces.knownSubspaces.isEmpty &&
                  !spaces.hasMoreSubspaces &&
                  canLinkSpace) {
                // fallback if there are no subspaces show, allow admins to access the buttons
                addSubspaceHeading('Subspaces', true);
              }

              if (spaces.otherRelations.isNotEmpty || canLinkSpace) {
                List<Widget> children = [
                  const Expanded(child: Text('Recommended Spaces')),
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
                      return SpaceCard(
                        key: Key(space.getRoomIdStr()),
                        space: space,
                      );
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
              ),
            ],
            loading: () => [
              const SliverToBoxAdapter(
                child: Center(
                  child: Text('Loading'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
