import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/categories/providers/categories_providers.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/link_room/actions/unlink_child_room.dart';
import 'package:acter/features/link_room/pages/link_room_page.dart';
import 'package:acter/features/space/providers/suggested_provider.dart';
import 'package:acter/features/spaces/providers/space_list_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LinkRoomTrailing extends ConsumerWidget {
  final bool canLink;
  final bool isLinked;
  final String parentId;
  final String roomId;

  const LinkRoomTrailing({
    super.key,
    required this.parentId,
    required this.roomId,
    required this.canLink,
    required this.isLinked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 100,
      child:
          isLinked
              ? OutlinedButton(
                onPressed: () => onTapUnlinkChildRoom(context, ref),
                key: Key('room-list-unlink-$roomId'),
                child: Text(lang.unlink),
              )
              : canLink
              ? OutlinedButton(
                onPressed: () => onTapLinkChildRoom(context, ref),
                key: Key('room-list-link-$roomId'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.success),
                ),
                child: Text(lang.link),
              )
              : null,
    );
  }

  Future<void> checkJoinRule(
    BuildContext context,
    WidgetRef ref,
    Room room,
    String parentSpaceId,
  ) async {
    final lang = L10n.of(context);
    final joinRule = room.joinRuleStr();
    List<String> currentRooms = [];
    bool parentCanSee = joinRule == 'public';
    String newRule = 'restricted';
    if (joinRule == 'restricted' || joinRule == 'knock_restricted') {
      currentRooms = asDartStringList(room.restrictedRoomIdsStr());
      parentCanSee = currentRooms.contains(parentSpaceId);
      newRule = joinRule;
    }

    if (!parentCanSee) {
      final spaceAvatarInfo = ref.read(roomAvatarInfoProvider(parentSpaceId));
      final parentSpaceName =
          spaceAvatarInfo.displayName ?? lang.theParentSpace;
      final roomName =
          // ignore: use_build_context_synchronously
          spaceAvatarInfo.displayName ?? lang.theSelectedRooms;
      bool shouldChange = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(lang.notVisible),
            content: Wrap(
              children: [
                Text(
                  lang.theCurrentJoinRulesOfSpace(roomName, parentSpaceName),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: <Widget>[
              OutlinedButton(
                key: LinkRoomPage.denyJoinRuleUpdateKey,
                child: Text(lang.noThanks),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
              ActerPrimaryActionButton(
                key: LinkRoomPage.confirmJoinRuleUpdateKey,
                child: Text(lang.yesPleaseUpdate),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
            ],
          );
        },
      );
      if (shouldChange) {
        currentRooms.add(parentSpaceId);

        final sdk = await ref.read(sdkProvider.future);
        final update = sdk.api.newJoinRuleBuilder();
        update.joinRule(newRule);
        for (final roomId in currentRooms) {
          update.addRoom(roomId);
        }
        await room.setJoinRule(update);
      }
    }
  }

  //Link child room
  Future<void> onTapLinkChildRoom(BuildContext context, WidgetRef ref) async {
    final lang = L10n.of(context);
    final room = await ref.read(maybeRoomProvider(roomId).future);
    if (room == null) {
      EasyLoading.showError(lang.roomNotFound);
      return;
    }

    final canLink =
        (await ref.read(
          roomMembershipProvider(roomId).future,
        ))?.canString('CanLinkSpaces') ==
        true;

    //Fetch selected parent space data and add given roomId as child
    final space = await ref.read(spaceProvider(parentId).future);
    await space.addChildRoom(roomId, false);

    //Make subspace
    if (canLink) {
      //Fetch selected room data and add given parentSpaceId as parent
      await room.addParentRoom(parentId, true);
      if (!context.mounted) return;
      await checkJoinRule(context, ref, room, parentId);
    } else {
      EasyLoading.showSuccess(lang.roomLinkedButNotUpgraded);
    }

    invalidateProviders(ref);
  }

  //Unlink child room
  Future<void> onTapUnlinkChildRoom(BuildContext context, WidgetRef ref) async {
    await unlinkChildRoom(context, ref, parentId: parentId, roomId: roomId);
    //Invalidate providers
    invalidateProviders(ref);
  }

  void invalidateProviders(WidgetRef ref) {
    //Invalidate providers
    ref.invalidate(spaceRelationsProvider(parentId));
    ref.invalidate(spaceRemoteRelationsProvider(parentId));
    ref.invalidate(subChatsListProvider(parentId));
    ref.invalidate(subSpacesListProvider(parentId));
    ref.invalidate(localCategoryListProvider);
  }
}
