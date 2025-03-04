import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomEventItem;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class RoomUpdateEvent extends ConsumerWidget {
  final bool isMe;
  final RoomEventItem item;
  final String roomId;
  const RoomUpdateEvent({
    super.key,
    required this.isMe,
    required this.item,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.only(
        left: 10,
        bottom: 5,
        right: 10,
      ),
      child: Text(
        getStateEventStr(context, ref, item),
        style: textTheme.labelSmall,
      ),
    );
  }

  String getStateEventStr(
    BuildContext context,
    WidgetRef ref,
    RoomEventItem item,
  ) {
    final lang = L10n.of(context);

    final senderId = item.sender();
    final eventType = item.eventType();
    final firstName = ref
        .watch(memberDisplayNameProvider((roomId: roomId, userId: senderId)))
        .valueOrNull;
    final msgContent = item.msgContent()?.body() ?? '';

    return switch (eventType) {
      'm.room.create' => isMe
          ? lang.chatYouRoomCreate
          : lang.chatRoomCreate(firstName ?? senderId),
      'm.room.join_rules' => isMe
          ? '${lang.chatYouUpdateJoinRules}: $msgContent'
          : '${lang.chatUpdateJoinRules(firstName ?? senderId)}: $msgContent',
      'm.room.power_levels' => isMe
          ? lang.chatYouUpdatePowerLevels
          : lang.chatUpdatePowerLevels(firstName ?? senderId),
      'm.room.name' => isMe
          ? '${lang.chatYouUpdateRoomName}: $msgContent'
          : '${lang.chatUpdateRoomName(firstName ?? senderId)}: $msgContent',
      'm.room.topic' => isMe
          ? '${lang.chatYouUpdateRoomTopic}: $msgContent'
          : '${lang.chatUpdateRoomTopic(firstName ?? senderId)}: $msgContent',
      'm.room.avatar' => isMe
          ? '${lang.chatYouUpdateRoomAvatar}: $msgContent'
          : '${lang.chatUpdateRoomAvatar(firstName ?? senderId)}: $msgContent',
      'm.room.aliases' => isMe
          ? lang.chatYouUpdateRoomAliases
          : lang.chatUpdateRoomAliases(firstName ?? senderId),
      'm.room.history_visibility' => isMe
          ? '${lang.chatYouUpdateRoomHistoryVisibility}: $msgContent'
          : '${lang.chatUpdateRoomHistoryVisibility(firstName ?? senderId)}: $msgContent',
      'm.room.encryption' => isMe
          ? lang.chatYouUpdateRoomEncryption
          : lang.chatUpdateRoomEncryption(firstName ?? senderId),
      'm.room.guest_access' => isMe
          ? '${lang.chatYouUpdateRoomGuestAccess}: $msgContent'
          : '${lang.chatUpdateRoomGuestAccess(firstName ?? senderId)}: $msgContent',
      'm.space.parent' => isMe
          ? lang.chatYouUpdateSpaceParent
          : lang.chatUpdateSpaceParent(firstName ?? senderId),
      'm.space.child' => isMe
          ? lang.chatYouUpdateSpaceChildren
          : lang.chatUpdateSpaceChildren(firstName ?? senderId),
      _ => eventType,
    };
  }
}
