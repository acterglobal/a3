import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/common/widgets/room/room_hierarchy_card.dart';
import 'package:acter/common/widgets/room/room_hierarchy_join_button.dart';
import 'package:acter/common/widgets/room/room_hierarchy_options_menu.dart';
import 'package:acter/features/space/providers/suggested_provider.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget localChatsListUI(
  WidgetRef ref,
  String spaceId,
  List<String> chats, {
  int? limit,
  bool showOptions = false,
}) {
  final suggestedId =
      ref.watch(suggestedIdsProvider(spaceId)).valueOrNull ?? [];
  return ListView.builder(
    shrinkWrap: true,
    itemCount: limit ?? chats.length,
    padding: EdgeInsets.zero,
    physics: const NeverScrollableScrollPhysics(),
    itemBuilder: (context, index) {
      final roomId = chats[index];
      return RoomCard(
        roomId: roomId,
        showParents: false,
        onTap: () => goToChat(context, roomId),
        trailing:
            showOptions
                ? RoomHierarchyOptionsMenu(
                  isSuggested: suggestedId.contains(roomId),
                  childId: roomId,
                  parentId: spaceId,
                )
                : null,
      );
    },
  );
}

Widget remoteChatsListUI(
  WidgetRef ref,
  String parentId,
  List<SpaceHierarchyRoomInfo> chats, {
  int? limit,
  bool showOptions = false,
}) {
  return ListView.builder(
    shrinkWrap: true,
    padding: EdgeInsets.zero,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: limit ?? chats.length,
    itemBuilder: (context, index) {
      final roomInfo = chats[index];
      final roomId = roomInfo.roomIdStr();
      return RoomHierarchyCard(
        parentId: parentId,
        roomInfo: roomInfo,
        trailing: Wrap(
          children: [
            RoomHierarchyJoinButton(
              joinRule: roomInfo.joinRuleStr().toLowerCase(),
              roomId: roomId,
              roomName: roomInfo.name() ?? roomId,
              viaServerName: roomInfo.viaServerNames().toDart(),
              forward: (roomId) {
                goToChat(context, roomId);
                // make sure the UI refreshes when the user comes back here
                ref.invalidate(spaceRelationsProvider(parentId));
                ref.invalidate(spaceRemoteRelationsProvider(parentId));
              },
            ),
            if (showOptions)
              RoomHierarchyOptionsMenu(
                isSuggested: roomInfo.suggested(),
                childId: roomId,
                parentId: parentId,
              ),
          ],
        ),
      );
    },
  );
}
