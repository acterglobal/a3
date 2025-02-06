import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/common/widgets/room/room_hierarchy_join_button.dart';
import 'package:acter/common/widgets/room/room_hierarchy_options_menu.dart';
import 'package:acter/common/widgets/room/room_hierarchy_card.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget localSpacesListUI(List<String> spaces, {int? limit}) {
  return ListView.builder(
    shrinkWrap: true,
    itemCount: limit ?? spaces.length,
    padding: EdgeInsets.zero,
    physics: const NeverScrollableScrollPhysics(),
    itemBuilder: (context, index) {
      final roomId = spaces[index];
      return RoomCard(
        key: Key('subspace-list-item-$roomId'),
        roomId: roomId,
        showParents: false,
        showVisibilityMark: true,
      );
    },
  );
}

Widget remoteSubSpacesListUI(
  WidgetRef ref,
  String spaceId,
  List<SpaceHierarchyRoomInfo> spaces, {
  int? limit,
  bool showOptions = false,
}) {
  if (spaces.isEmpty) {
    return const SizedBox.shrink();
  }

  int itemCount = spaces.length;
  if (limit != null && limit < itemCount) {
    itemCount = limit;
  }

  return GridView.builder(
    itemCount: itemCount,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 1,
      childAspectRatio: 4.0,
      mainAxisExtent: 100,
    ),
    shrinkWrap: true,
    itemBuilder: (context, index) {
      final roomInfo = spaces[index];
      final roomId = roomInfo.roomIdStr();
      return RoomHierarchyCard(
        key: Key('subspace-list-item-$roomId'),
        roomInfo: roomInfo,
        parentId: spaceId,
        indicateIfSuggested: true,
        trailing: Wrap(
          children: [
            RoomHierarchyJoinButton(
              joinRule: roomInfo.joinRuleStr().toLowerCase(),
              roomId: roomId,
              roomName: roomInfo.name() ?? roomId,
              viaServerName: roomInfo.viaServerNames().toDart(),
              forward: (spaceId) {
                goToSpace(context, spaceId);
                ref.invalidate(spaceRelationsProvider(spaceId));
                ref.invalidate(spaceRemoteRelationsProvider(spaceId));
              },
            ),
            RoomHierarchyOptionsMenu(
              isSuggested: roomInfo.suggested(),
              childId: roomId,
              parentId: spaceId,
            ),
          ],
        ),
      );
    },
  );
}
