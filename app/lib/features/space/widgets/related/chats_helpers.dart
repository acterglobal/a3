import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/common/widgets/room/room_hierarchy_card.dart';
import 'package:acter/common/widgets/room/room_hierarchy_join_button.dart';
import 'package:acter/common/widgets/room/room_hierarchy_options_menu.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::space::related::chats_helpers');

Widget chatsListUI(
  WidgetRef ref,
  String parentId,
  List<String> chats,
  int chatsLimit, {
  bool showOptions = false,
  bool showSuggestedMarkIfGiven = true,
}) {
  final suggestedId =
      ref.watch(suggestedIdsProvider(parentId)).valueOrNull ?? [];
  return ListView.builder(
    shrinkWrap: true,
    itemCount: chatsLimit,
    padding: EdgeInsets.zero,
    physics: const NeverScrollableScrollPhysics(),
    itemBuilder: (context, index) {
      final roomId = chats[index];
      return RoomCard(
        roomId: roomId,
        showParents: false,
        showSuggestedMark:
            showSuggestedMarkIfGiven && suggestedId.contains(roomId),
        onTap: () => goToChat(context, roomId),
        trailing: showOptions
            ? RoomHierarchyOptionsMenu(
                isSuggested: suggestedId.contains(roomId),
                childId: roomId,
                parentId: parentId,
              )
            : null,
      );
    },
  );
}

Widget renderRemoteChats(
  BuildContext context,
  WidgetRef ref,
  String parentId,
  List<SpaceHierarchyRoomInfo> chats,
  int? maxItems, {
  bool showSuggestedMarkIfGiven = true,
  bool renderMenu = true,
}) {
  if (chats.isEmpty) return const SizedBox.shrink();
  return ListView.builder(
    shrinkWrap: true,
    padding: EdgeInsets.zero,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: maxItems ?? chats.length,
    itemBuilder: (context, index) {
      final roomInfo = chats[index];
      final roomId = roomInfo.roomIdStr();
      return RoomHierarchyCard(
        indicateIfSuggested: showSuggestedMarkIfGiven,
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
            if (renderMenu)
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

Widget renderFurther(
  BuildContext context,
  WidgetRef ref,
  String spaceId,
  int? maxItems,
) {
  final lang = L10n.of(context);
  final relatedChatsLoader = ref.watch(remoteChatRelationsProvider(spaceId));
  return relatedChatsLoader.when(
    data: (chats) => renderRemoteChats(context, ref, spaceId, chats, maxItems),
    error: (e, s) {
      _log.severe('Failed to load the related chats', e, s);
      return Card(
        child: Text(lang.errorLoadingRelatedChats(e)),
      );
    },
    loading: () => Skeletonizer(
      child: Card(
        child: Text(lang.loadingOtherChats),
      ),
    ),
  );
}
