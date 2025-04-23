import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat_ng::widgets::room_update');

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
    final stateText = getStateEventStr(context, ref, item);
    if (stateText == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.only(left: 10, bottom: 5, right: 10),
      child: Text(stateText, style: Theme.of(context).textTheme.labelSmall),
    );
  }

  String? getStateEventStr(
    BuildContext context,
    WidgetRef ref,
    TimelineEventItem item,
  ) {
    final lang = L10n.of(context);

    final senderId = item.sender();
    final firstName =
        ref
            .watch(
              memberDisplayNameProvider((roomId: roomId, userId: senderId)),
            )
            .valueOrNull;
    final senderName = firstName ?? simplifyUserId(senderId) ?? senderId;
    final msgContent = item.message()?.body() ?? '';

    return switch (item.eventType()) {
      'm.policy.rule.room' => getMessageOnPolicyRuleRoom(
        lang,
        isMe,
        senderName,
      ),
      'm.policy.rule.server' => getMessageOnPolicyRuleServer(
        lang,
        isMe,
        senderName,
      ),
      'm.policy.rule.user' => getMessageOnPolicyRuleUser(
        lang,
        isMe,
        senderName,
      ),
      'm.room.create' =>
        isMe
            ? lang.chatYouRoomCreate
            : lang.chatRoomCreate(firstName ?? senderId),
      'm.room.join_rules' =>
        isMe
            ? '${lang.chatYouUpdateJoinRules}: $msgContent'
            : '${lang.chatUpdateJoinRules(firstName ?? senderId)}: $msgContent',
      'm.room.power_levels' =>
        isMe
            ? lang.chatYouUpdatePowerLevels
            : lang.chatUpdatePowerLevels(firstName ?? senderId),
      'm.room.name' =>
        isMe
            ? '${lang.chatYouUpdateRoomName}: $msgContent'
            : '${lang.chatUpdateRoomName(firstName ?? senderId)}: $msgContent',
      'm.room.topic' =>
        isMe
            ? '${lang.chatYouUpdateRoomTopic}: $msgContent'
            : '${lang.chatUpdateRoomTopic(firstName ?? senderId)}: $msgContent',
      'm.room.avatar' =>
        isMe
            ? lang.chatYouUpdateRoomAvatar
            : lang.chatUpdateRoomAvatar(firstName ?? senderId),
      'm.room.aliases' =>
        isMe
            ? lang.chatYouUpdateRoomAliases
            : lang.chatUpdateRoomAliases(firstName ?? senderId),
      'm.room.canonical_alias' =>
        isMe
            ? lang.chatYouUpdateRoomCanonicalAlias
            : lang.chatUpdateRoomCanonicalAlias(firstName ?? senderId),
      'm.room.history_visibility' =>
        isMe
            ? '${lang.chatYouUpdateRoomHistoryVisibility}: $msgContent'
            : '${lang.chatUpdateRoomHistoryVisibility(firstName ?? senderId)}: $msgContent',
      'm.room.encryption' =>
        isMe
            ? lang.chatYouUpdateRoomEncryption
            : lang.chatUpdateRoomEncryption(firstName ?? senderId),
      'm.room.guest_access' =>
        isMe
            ? lang.chatYouUpdateRoomGuestAccess
            : lang.chatUpdateRoomGuestAccess(firstName ?? senderId),
      'm.room.third_party_invite' =>
        isMe
            ? lang.chatYouUpdateRoomThirdPartyInvite
            : lang.chatUpdateRoomThirdPartyInvite(firstName ?? senderId),
      'm.room.server_acl' => lang.chatUpdateRoomServerAcl,
      'm.room.tombstone' => '${lang.chatUpdateRoomTombstone}: $msgContent',
      'm.room.pinned_events' =>
        isMe
            ? lang.chatYouUpdateRoomPinnedEvents
            : lang.chatUpdateRoomPinnedEvents(firstName ?? senderId),
      'm.space.parent' =>
        isMe
            ? lang.chatYouUpdateSpaceParent
            : lang.chatUpdateSpaceParent(firstName ?? senderId),
      'm.space.child' =>
        isMe
            ? lang.chatYouUpdateSpaceChildren
            : lang.chatUpdateSpaceChildren(firstName ?? senderId),
      _ => null,
    };
  }

  String? getMessageOnPolicyRuleRoom(L10n lang, bool isMe, String senderName) {
    final content = item.policyRuleRoomContent();
    if (content == null) {
      _log.severe('failed to get content of policy rule room change');
      return null;
    }
    switch (content.entityChange()) {
      case 'Changed':
        final newVal = content.entityNewVal();
        final oldVal = content.entityOldVal() ?? '';
        if (isMe) {
          return lang.roomStatePolicyRuleRoomEntityYouChanged(oldVal, newVal);
        } else {
          return lang.roomStatePolicyRuleRoomEntityOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.entityNewVal();
        if (isMe) {
          return lang.roomStatePolicyRuleRoomEntityYouSet(newVal);
        } else {
          return lang.roomStatePolicyRuleRoomEntityOtherSet(senderName, newVal);
        }
    }
    switch (content.reasonChange()) {
      case 'Changed':
        final newVal = content.reasonNewVal();
        final oldVal = content.reasonOldVal() ?? '';
        if (isMe) {
          return lang.roomStatePolicyRuleRoomReasonYouChanged(oldVal, newVal);
        } else {
          return lang.roomStatePolicyRuleRoomReasonOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.reasonNewVal();
        if (isMe) {
          return lang.roomStatePolicyRuleRoomReasonYouSet(newVal);
        } else {
          return lang.roomStatePolicyRuleRoomReasonOtherSet(senderName, newVal);
        }
    }
    switch (content.recommendationChange()) {
      case 'Changed':
        final newVal = content.recommendationNewVal();
        final oldVal = content.recommendationOldVal() ?? '';
        if (isMe) {
          return lang.roomStatePolicyRuleRoomRecommendationYouChanged(
            oldVal,
            newVal,
          );
        } else {
          return lang.roomStatePolicyRuleRoomRecommendationOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.recommendationNewVal();
        if (isMe) {
          return lang.roomStatePolicyRuleRoomRecommendationYouSet(newVal);
        } else {
          return lang.roomStatePolicyRuleRoomRecommendationOtherSet(
            senderName,
            newVal,
          );
        }
    }
    return null;
  }

  String? getMessageOnPolicyRuleServer(
    L10n lang,
    bool isMe,
    String senderName,
  ) {
    final content = item.policyRuleServerContent();
    if (content == null) {
      _log.severe('failed to get content of policy rule server change');
      return null;
    }
    switch (content.entityChange()) {
      case 'Changed':
        final newVal = content.entityNewVal();
        final oldVal = content.entityOldVal() ?? '';
        if (isMe) {
          return lang.roomStatePolicyRuleServerEntityYouChanged(oldVal, newVal);
        } else {
          return lang.roomStatePolicyRuleServerEntityOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.entityNewVal();
        if (isMe) {
          return lang.roomStatePolicyRuleServerEntityYouSet(newVal);
        } else {
          return lang.roomStatePolicyRuleServerEntityOtherSet(
            senderName,
            newVal,
          );
        }
    }
    switch (content.reasonChange()) {
      case 'Changed':
        final newVal = content.reasonNewVal();
        final oldVal = content.reasonOldVal() ?? '';
        if (isMe) {
          return lang.roomStatePolicyRuleServerReasonYouChanged(oldVal, newVal);
        } else {
          return lang.roomStatePolicyRuleServerReasonOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.reasonNewVal();
        if (isMe) {
          return lang.roomStatePolicyRuleServerReasonYouSet(newVal);
        } else {
          return lang.roomStatePolicyRuleServerReasonOtherSet(
            senderName,
            newVal,
          );
        }
    }
    switch (content.recommendationChange()) {
      case 'Changed':
        final newVal = content.recommendationNewVal();
        final oldVal = content.recommendationOldVal() ?? '';
        if (isMe) {
          return lang.roomStatePolicyRuleServerRecommendationYouChanged(
            oldVal,
            newVal,
          );
        } else {
          return lang.roomStatePolicyRuleServerRecommendationOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.recommendationNewVal();
        if (isMe) {
          return lang.roomStatePolicyRuleServerRecommendationYouSet(newVal);
        } else {
          return lang.roomStatePolicyRuleServerRecommendationOtherSet(
            senderName,
            newVal,
          );
        }
    }
    return null;
  }

  String? getMessageOnPolicyRuleUser(L10n lang, bool isMe, String senderName) {
    final content = item.policyRuleUserContent();
    if (content == null) {
      _log.severe('failed to get content of policy rule user change');
      return null;
    }
    switch (content.entityChange()) {
      case 'Changed':
        final newVal = content.entityNewVal();
        final oldVal = content.entityOldVal() ?? '';
        if (isMe) {
          return lang.roomStatePolicyRuleUserEntityYouChanged(oldVal, newVal);
        } else {
          return lang.roomStatePolicyRuleUserEntityOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.entityNewVal();
        if (isMe) {
          return lang.roomStatePolicyRuleUserEntityYouSet(newVal);
        } else {
          return lang.roomStatePolicyRuleUserEntityOtherSet(senderName, newVal);
        }
    }
    switch (content.reasonChange()) {
      case 'Changed':
        final newVal = content.reasonNewVal();
        final oldVal = content.reasonOldVal() ?? '';
        if (isMe) {
          return lang.roomStatePolicyRuleUserReasonYouChanged(oldVal, newVal);
        } else {
          return lang.roomStatePolicyRuleUserReasonOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.reasonNewVal();
        if (isMe) {
          return lang.roomStatePolicyRuleUserReasonYouSet(newVal);
        } else {
          return lang.roomStatePolicyRuleUserReasonOtherSet(senderName, newVal);
        }
    }
    switch (content.recommendationChange()) {
      case 'Changed':
        final newVal = content.recommendationNewVal();
        final oldVal = content.recommendationOldVal() ?? '';
        if (isMe) {
          return lang.roomStatePolicyRuleUserRecommendationYouChanged(
            oldVal,
            newVal,
          );
        } else {
          return lang.roomStatePolicyRuleUserRecommendationOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.recommendationNewVal();
        if (isMe) {
          return lang.roomStatePolicyRuleUserRecommendationYouSet(newVal);
        } else {
          return lang.roomStatePolicyRuleUserRecommendationOtherSet(
            senderName,
            newVal,
          );
        }
    }
    return null;
  }
}
