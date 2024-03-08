import 'dart:math';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/common/widgets/spaces/space_card.dart';
import 'package:acter/common/widgets/spaces/space_hierarchy_card.dart';
import 'package:acter/features/space/providers/space_providers.dart';
import 'package:acter/features/space/providers/notifiers/space_hierarchy_notifier.dart';
import 'package:acter/features/space/widgets/space_header.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

class RelatedSpacesPage extends ConsumerWidget {
  static const moreOptionKey = Key('related-spaces-more-actions');
  static const createSubspaceKey = Key('related-spaces-more-create-subspace');
  static const linkSubspaceKey = Key('related-spaces-more-link-subspace');
  final String spaceIdOrAlias;

  const RelatedSpacesPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spaceRelationsOverviewProvider(spaceIdOrAlias));
    // get platform of context.
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: primaryGradient),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SpaceHeader(spaceIdOrAlias: spaceIdOrAlias),
          ),
          ...spaces.when(
            data: (spaces) => renderSpaces(spaces, context, ref),
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

  Widget renderTools(BuildContext context) {
    return PopupMenuButton(
      icon: Icon(
        Atlas.plus_circle,
        key: moreOptionKey,
        color: Theme.of(context).colorScheme.neutral5,
      ),
      iconSize: 28,
      color: Theme.of(context).colorScheme.surface,
      itemBuilder: (BuildContext context) => <PopupMenuEntry>[
        PopupMenuItem(
          key: createSubspaceKey,
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
          key: linkSubspaceKey,
          onTap: () => context.pushNamed(
            Routes.linkSubspace.name,
            pathParameters: {'spaceId': spaceIdOrAlias},
          ),
          child: const Row(
            children: <Widget>[
              Text('Link existing Space'),
              Spacer(),
              Icon(Atlas.connection),
            ],
          ),
        ),
      ],
    );
  }

  Widget renderSubspaceHeading(
    BuildContext context,
    String title, {
    bool canLinkSpace = false,
    bool withTools = false,
  }) {
    return SliverToBoxAdapter(
      child: Row(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(title),
          ),
        ),
        if (canLinkSpace && withTools) renderTools(context),
      ],),
    );
  }

  Widget? renderParentsHeader(
    SpaceRelationsOverview spaces,
  ) {
    if (spaces.parents.isNotEmpty || spaces.mainParent != null) {
      return const SliverToBoxAdapter(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Parents'),
              ),
            ),
          ],
        ),
      );
    }
    return null;
  }

  Widget? renderMainParent(
    SpaceRelationsOverview spaces,
  ) {
    if (spaces.mainParent == null) {
      return null;
    }
    final space = spaces.mainParent!;
    return SliverToBoxAdapter(
      child: SpaceCard(
        key: Key(space.getRoomIdStr()),
        space: space,
      ),
    );
  }

  Widget? renderFurtherParent(
    SpaceRelationsOverview spaces,
    int crossAxisCount,
  ) {
    if (spaces.parents.isEmpty) {
      return null;
    }
    return SliverGrid.builder(
      itemCount: spaces.parents.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 4.0,
        mainAxisExtent: 100,
      ),
      itemBuilder: (context, index) {
        final space = spaces.parents[index];
        return SpaceCard(
          key: Key('parent-list-item-${space.getRoomIdStr()}'),
          space: space,
          showParent: false,
        );
      },
    );
  }

  List<Widget>? renderKnownSubspaces(
    BuildContext context,
    SpaceRelationsOverview spaces,
    bool canLinkSpace,
    int crossAxisCount,
  ) {
    if (spaces.knownSubspaces.isEmpty) {
      return null;
    }

    return [
      spaces.hasMoreSubspaces
          ? renderSubspaceHeading(
              context,
              'My Subspaces',
              canLinkSpace: canLinkSpace,
              withTools: false,
            )
          : renderSubspaceHeading(
              context,
              'Subspaces',
              canLinkSpace: canLinkSpace,
              withTools: true,
            ),
      SliverGrid.builder(
        itemCount: spaces.knownSubspaces.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 9.0,
          mainAxisExtent: 100,
        ),
        itemBuilder: (context, index) {
          final space = spaces.knownSubspaces[index];
          return SpaceCard(
            key: Key('subspace-list-item-${space.getRoomIdStr()}'),
            space: space,
            showParent: false,
          );
        },
      ),
    ];
  }

  List<Widget>? renderMoreSubspaces(
    BuildContext context,
    SpaceRelationsOverview spaces,
    bool canLinkSpace,
    int crossAxisCount,
  ) {
    if (!spaces.hasMoreSubspaces) {
      return null;
    }

    return [
      spaces.knownSubspaces.isEmpty
          ? renderSubspaceHeading(
              context,
              'Subspaces',
              canLinkSpace: canLinkSpace,
              withTools: true,
            )
          : renderSubspaceHeading(
              context,
              'More Subspaces',
              canLinkSpace: canLinkSpace,
              withTools: true,
            ),
      RiverPagedBuilder<Next?, SpaceHierarchyRoomInfo>.autoDispose(
        firstPageKey: const Next(isStart: true),
        provider: remoteSpaceHierarchyProvider(spaces),
        itemBuilder: (context, item, index) => SpaceHierarchyCard(
          key: Key('subspace-list-item-${item.roomIdStr()}'),
          space: item,
        ),
        pagedBuilder: (controller, builder) => PagedSliverList(
          pagingController: controller,
          builderDelegate: builder,
        ),
      ),
    ];
  }

  Widget? renderFallbackSubspaceHeader(
    BuildContext context,
    SpaceRelationsOverview spaces,
    bool canLinkSpace,
  ) {
    if (spaces.knownSubspaces.isEmpty &&
        !spaces.hasMoreSubspaces &&
        canLinkSpace) {
      // fallback if there are no subspaces show, allow admins to access the buttons

      return renderSubspaceHeading(
        context,
        'Subspaces',
        canLinkSpace: canLinkSpace,
        withTools: true,
      );
    }
    return null;
  }

  List<Widget>? renderOtherRelations(
    BuildContext context,
    SpaceRelationsOverview spaces,
    bool canLinkSpace,
    int crossAxisCount,
  ) {
    if (spaces.otherRelations.isEmpty || !canLinkSpace) {
      return null;
    }

    return [
      if (spaces.otherRelations.isNotEmpty || canLinkSpace)
        SliverToBoxAdapter(
          child: Row(
            children: [
              const Expanded(child: Text('Recommended Spaces')),
              IconButton(
                icon: Icon(
                  Atlas.plus_circle,
                  color: Theme.of(context).colorScheme.neutral5,
                ),
                onPressed: () => context.pushNamed(
                  Routes.linkRecommended.name,
                  pathParameters: {'spaceId': spaceIdOrAlias},
                ),
              ),
            ],
          ),
        ),
      if (spaces.otherRelations.isNotEmpty)
        SliverGrid.builder(
          itemCount: spaces.otherRelations.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 4.0,
            mainAxisExtent: 100,
          ),
          itemBuilder: (context, index) {
            final space = spaces.otherRelations[index];
            return SpaceCard(
              key: Key('subspace-list-item-${space.getRoomIdStr()}'),
              space: space,
            );
          },
        ),
    ];
  }

  List<Widget> renderSpaces(
    SpaceRelationsOverview spaces,
    BuildContext context,
    WidgetRef ref,
  ) {
    final widthCount = (MediaQuery.of(context).size.width ~/ 300).toInt();
    const int minCount = 3;
    final crossAxisCount = max(1, min(widthCount, minCount));

    final canLinkSpace = spaces.membership?.canString('CanLinkSpaces') ?? false;

    final parentsHeader = renderParentsHeader(spaces);
    final mainParent = renderMainParent(spaces);
    final furtherParents = renderFurtherParent(spaces, crossAxisCount);
    final knownSubspaces = renderKnownSubspaces(
      context,
      spaces,
      canLinkSpace,
      crossAxisCount,
    );

    final moreSubspaces = renderMoreSubspaces(
      context,
      spaces,
      canLinkSpace,
      crossAxisCount,
    );
    final fallbackSubspacesHeader = renderFallbackSubspaceHeader(
      context,
      spaces,
      canLinkSpace,
    );
    final otherRelations = renderOtherRelations(
      context,
      spaces,
      canLinkSpace,
      crossAxisCount,
    );

    final items = [
      if (parentsHeader != null) parentsHeader,
      if (mainParent != null) mainParent,
      if (furtherParents != null) furtherParents,
      if (knownSubspaces != null) ...knownSubspaces,
      if (moreSubspaces != null) ...moreSubspaces,
      if (fallbackSubspacesHeader != null) fallbackSubspacesHeader,
      if (otherRelations != null) ...otherRelations,
    ];

    if (items.isNotEmpty) {
      return items;
    }

    // fallback when nothing was found
    return [
      SliverToBoxAdapter(
        child: Center(
          heightFactor: 1,
          child: EmptyState(
            title: 'No connected spaces',
            subtitle:
                'In connected spaces, you can focus on specific actions or campaigns of your working groups and start organizing.',
            image: 'assets/images/empty_space.svg',
            primaryButton: canLinkSpace
                ? ElevatedButton(
                    onPressed: () => context.pushNamed(
                      Routes.createSpace.name,
                      queryParameters: {
                        'parentSpaceId': spaceIdOrAlias,
                      },
                    ),
                    child: const Text('Create New Spaces'),
                  )
                : null,
          ),
        ),
      ),
    ];
  }
}
