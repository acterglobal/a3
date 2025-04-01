import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/room_state.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/l10n/generated/l10n.dart';

class RoomUpdateEvent extends ConsumerWidget {
  final bool isMe;
  final TimelineEventItem item;
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
    final stateText = getStateEventStr(context, ref, item);
    if (stateText == null) return SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.only(left: 10, bottom: 5, right: 10),
      child: Text(stateText, style: textTheme.labelSmall),
    );
  }

  String? getStateEventStr(
    BuildContext context,
    WidgetRef ref,
    TimelineEventItem item,
  ) {
    final lang = L10n.of(context);
    String myId = ref.watch(myUserIdStrProvider);

    final senderId = item.sender();
    final eventType = item.eventType();
    final senderName =
        ref
            .watch(
              memberDisplayNameProvider((roomId: roomId, userId: senderId)),
            )
            .valueOrNull ??
        simplifyUserId(senderId) ??
        senderId;

    return switch (eventType) {
      'm.policy.rule.room' => getStateOnPolicyRuleRoom(
        lang,
        item,
        myId,
        senderId,
        senderName,
      ),
      'm.policy.rule.server' => getStateOnPolicyRuleServer(
        lang,
        item,
        myId,
        senderId,
        senderName,
      ),
      'm.policy.rule.user' => getStateOnPolicyRuleUser(
        lang,
        item,
        myId,
        senderId,
        senderName,
      ),
      'm.room.aliases' => getStateOnRoomAliases(
        lang,
        item,
        myId,
        senderId,
        senderName,
      ),
      'm.room.avatar' => getStateOnRoomAvatar(
        lang,
        item,
        myId,
        senderId,
        senderName,
      ),
      'm.room.canonical_alias' => getStateOnRoomCanonicalAlias(
        lang,
        item,
        myId,
        senderId,
        senderName,
      ),
      'm.room.create' => getStateOnRoomCreate(lang, myId, senderId, senderName),
      'm.room.encryption' => getStateOnRoomEncryption(
        lang,
        item,
        myId,
        senderId,
        senderName,
      ),
      'm.room.guest_access' => getStateOnRoomGuestAccess(
        lang,
        item,
        myId,
        senderId,
        senderName,
      ),
      'm.room.history_visibility' => getStateOnRoomHistoryVisibility(
        lang,
        item,
        myId,
        senderId,
        senderName,
      ),
      'm.room.join_rules' => getStateOnRoomJoinRules(
        lang,
        item,
        myId,
        senderId,
        senderName,
      ),
      'm.room.name' => getStateOnRoomName(
        lang,
        item,
        myId,
        senderId,
        senderName,
      ),
      'm.room.pinned_events' => getStateOnRoomPinnedEvents(
        lang,
        item,
        myId,
        senderId,
        senderName,
      ),
      'm.room.power_levels' => getStateOnRoomPowerLevels(
        lang,
        item,
        myId,
        senderId,
        senderName,
      ),
      'm.room.server_acl' => getStateOnRoomServerAcl(
        lang,
        item,
        myId,
        senderId,
        senderName,
      ),
      'm.room.third_party_invite' => getStateOnRoomThirdPartyInvite(
        lang,
        item,
        myId,
        senderId,
        senderName,
      ),
      'm.room.tombstone' => getStateOnRoomTombstone(
        lang,
        item,
        myId,
        senderId,
        senderName,
      ),
      'm.room.topic' => getStateOnRoomTopic(
        lang,
        item,
        myId,
        senderId,
        senderName,
      ),
      'm.space.child' => getStateOnSpaceChild(
        lang,
        item,
        myId,
        senderId,
        senderName,
      ),
      'm.space.parent' => getStateOnSpaceParent(
        lang,
        item,
        myId,
        senderId,
        senderName,
      ),
      _ => null,
    };
  }
}
