import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/spaces/space_card.dart';
import 'package:acter/common/widgets/spaces/space_hierarchy_card.dart';
import 'package:acter/features/space/providers/notifiers/space_hierarchy_notifier.dart';
import 'package:acter/features/space/providers/space_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class RelatedSpaces extends StatelessWidget {
  static const moreOptionKey = Key('related-spaces-more-actions');
  static const createSubspaceKey = Key('related-spaces-more-create-subspace');
  static const linkSubspaceKey = Key('related-spaces-more-link-subspace');

  final String spaceIdOrAlias;
  final SpaceRelationsOverview spaces;
  final int crossAxisCount;
  final Widget fallback;
  final bool showParents;

  const RelatedSpaces({
    super.key,
    required this.spaceIdOrAlias,
    required this.spaces,
    required this.fallback,
    this.showParents = true,
    this.crossAxisCount = 1,
  });

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
          child: Row(
            children: <Widget>[
              Text(L10n.of(context).createSubspace),
              const Spacer(),
              const Icon(Atlas.connection),
            ],
          ),
        ),
        PopupMenuItem(
          key: linkSubspaceKey,
          onTap: () => context.pushNamed(
            Routes.linkSubspace.name,
            pathParameters: {'spaceId': spaceIdOrAlias},
          ),
          child: Row(
            children: <Widget>[
              Text(L10n.of(context).linkExistingSpace),
              const Spacer(),
              const Icon(Atlas.connection),
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
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(title),
            ),
          ),
          if (canLinkSpace && withTools) renderTools(context),
        ],
      ),
    );
  }

  Widget? renderParentsHeader(BuildContext context) {
    if (!showParents || (spaces.parents.isEmpty && spaces.mainParent != null)) {
      return null;
    }
    return SliverToBoxAdapter(
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(L10n.of(context).parents),
            ),
          ),
        ],
      ),
    );
  }

  Widget? renderMainParent() {
    if (!showParents || spaces.mainParent == null) {
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

  Widget? renderFurtherParent() {
    if (!showParents || spaces.parents.isEmpty) {
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
    bool canLinkSpace,
  ) {
    if (spaces.knownSubspaces.isEmpty) {
      return null;
    }

    return [
      spaces.hasMoreSubspaces
          ? renderSubspaceHeading(
              context,
              L10n.of(context).mySubspaces,
              canLinkSpace: canLinkSpace,
              withTools: false,
            )
          : renderSubspaceHeading(
              context,
              L10n.of(context).subspaces,
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
    bool canLinkSpace,
  ) {
    if (!spaces.hasMoreSubspaces) {
      return null;
    }

    return [
      spaces.knownSubspaces.isEmpty
          ? renderSubspaceHeading(
              context,
              L10n.of(context).subspaces,
              canLinkSpace: canLinkSpace,
              withTools: true,
            )
          : renderSubspaceHeading(
              context,
              L10n.of(context).moreSubspaces,
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
    bool canLinkSpace,
  ) {
    if (spaces.knownSubspaces.isEmpty &&
        !spaces.hasMoreSubspaces &&
        canLinkSpace) {
      // fallback if there are no subspaces show, allow admins to access the buttons

      return renderSubspaceHeading(
        context,
        L10n.of(context).subspaces,
        canLinkSpace: canLinkSpace,
        withTools: true,
      );
    }
    return null;
  }

  List<Widget>? renderOtherRelations(
    BuildContext context,
    bool canLinkSpace,
  ) {
    if (spaces.otherRelations.isEmpty || !canLinkSpace) {
      return null;
    }

    return [
      if (spaces.otherRelations.isNotEmpty || canLinkSpace)
        SliverToBoxAdapter(
          child: Row(
            children: [
              Expanded(child: Text(L10n.of(context).recommendedSpaces)),
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

  @override
  Widget build(BuildContext context) {
    final canLinkSpace = spaces.membership?.canString('CanLinkSpaces') ?? false;

    final parentsHeader = renderParentsHeader(context);
    final mainParent = renderMainParent();
    final furtherParents = renderFurtherParent();
    final knownSubspaces = renderKnownSubspaces(
      context,
      canLinkSpace,
    );

    final moreSubspaces = renderMoreSubspaces(
      context,
      canLinkSpace,
    );
    final fallbackSubspacesHeader =
        renderFallbackSubspaceHeader(context, canLinkSpace);
    final otherRelations = renderOtherRelations(
      context,
      canLinkSpace,
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
      return SliverMainAxisGroup(slivers: items);
    } else {
      return fallback;
    }
  }
}
