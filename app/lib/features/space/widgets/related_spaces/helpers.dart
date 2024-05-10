import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/spaces/space_card.dart';
import 'package:acter/common/widgets/spaces/space_hierarchy_card.dart';
import 'package:acter/features/space/providers/notifiers/space_hierarchy_notifier.dart';
import 'package:acter/features/space/providers/space_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

List<Widget>? _renderKnownSubspaces(
  BuildContext context,
  bool canLinkSpace,
  String spaceIdOrAlias,
  SpaceRelationsOverview spaces,
) {
  if (spaces.knownSubspaces.isEmpty) {
    return null;
  }

  return [
    GridView.builder(
      itemCount: spaces.knownSubspaces.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 4.0,
        mainAxisExtent: 100,
      ),
      shrinkWrap: true,
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

List<Widget>? _renderMoreSubspaces(
  BuildContext context,
  bool canLinkSpace,
  String spaceIdOrAlias,
  SpaceRelationsOverview spaces, {
  bool renderHeader = true,
}) {
  if (!spaces.hasMoreSubspaces) {
    return null;
  }

  return [
    RiverPagedBuilder<Next?, SpaceHierarchyRoomInfo>.autoDispose(
      firstPageKey: const Next(isStart: true),
      provider: remoteSpaceHierarchyProvider(spaces),
      itemBuilder: (context, item, index) => SpaceHierarchyCard(
        key: Key('subspace-list-item-${item.roomIdStr()}'),
        roomInfo: item,
        parentId: spaceIdOrAlias,
      ),
      noItemsFoundIndicatorBuilder: (context, controller) =>
          const SizedBox.shrink(),
      pagedBuilder: (controller, builder) => PagedListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        pagingController: controller,
        builderDelegate: builder,
      ),
    ),
  ];
}

Widget? renderSubSpaces(
  BuildContext context,
  String spaceIdOrAlias,
  SpaceRelationsOverview spaces, {
  int crossAxisCount = 1,
  Widget? Function()? titleBuilder,
}) {
  final canLinkSpace = spaces.membership?.canString('CanLinkSpaces') ?? false;

  final knownSubspaces = _renderKnownSubspaces(
    context,
    canLinkSpace,
    spaceIdOrAlias,
    spaces,
    // crossAxisCount: crossAxisCount,
  );

  final moreSubspaces = _renderMoreSubspaces(
    context,
    canLinkSpace,
    spaceIdOrAlias,
    spaces,
    renderHeader: false,
  );

  final items = [
    if (knownSubspaces != null) ...knownSubspaces,
    if (moreSubspaces != null) ...moreSubspaces,
  ];

  if (items.isNotEmpty) {
    if (titleBuilder != null) {
      final title = titleBuilder();
      if (title != null) {
        items.insert(0, title);
      }
    }
    return SingleChildScrollView(
      child: Column(
        children: items,
      ),
    );
  } else {
    return null;
  }
}
