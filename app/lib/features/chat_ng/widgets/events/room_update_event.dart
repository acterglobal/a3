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
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      alignment: Alignment.center,
      child: Text(
        stateText,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
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
      'm.room.avatar' => getMessageOnRoomAvatar(lang, isMe, senderName),
      'm.room.create' => getMessageOnRoomCreate(lang, isMe, senderName),
      'm.room.encryption' => getMessageOnRoomEncryption(lang, isMe, senderName),
      'm.room.guest_access' => getMessageOnRoomGuestAccess(
        lang,
        isMe,
        senderName,
      ),
      'm.room.history_visibility' => getMessageOnRoomHistoryVisibility(
        lang,
        isMe,
        senderName,
      ),
      'm.room.join_rules' => getMessageOnRoomJoinRules(lang, isMe, senderName),
      'm.room.name' => getMessageOnRoomName(lang, isMe, senderName),
      'm.room.pinned_events' => getMessageOnRoomPinnedEvents(
        lang,
        isMe,
        senderName,
      ),
      'm.room.power_levels' => getMessageOnRoomPowerLevels(
        lang,
        isMe,
        senderName,
      ),
      'm.room.server_acl' => getMessageOnRoomServerAcl(lang, isMe, senderName),
      'm.room.tombstone' => getMessageOnRoomTombstone(lang, isMe, senderName),
      'm.room.topic' => getMessageOnRoomTopic(lang, isMe, senderName),
      'm.space.child' => getMessageOnSpaceChild(lang, isMe, senderName),
      'm.space.parent' => getMessageOnSpaceParent(lang, isMe, senderName),
      'm.room.aliases' =>
        isMe
            ? lang.chatYouUpdateRoomAliases
            : lang.chatUpdateRoomAliases(firstName ?? senderId),
      'm.room.canonical_alias' =>
        isMe
            ? lang.chatYouUpdateRoomCanonicalAlias
            : lang.chatUpdateRoomCanonicalAlias(firstName ?? senderId),
      'm.room.third_party_invite' =>
        isMe
            ? lang.chatYouUpdateRoomThirdPartyInvite
            : lang.chatUpdateRoomThirdPartyInvite(firstName ?? senderId),
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

  String? getMessageOnRoomAvatar(L10n lang, bool isMe, String senderName) {
    final content = item.roomAvatarContent();
    if (content == null) {
      _log.severe('failed to get content of room avatar change');
      return null;
    }
    switch (content.urlChange()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomAvatarUrlYouChanged;
        } else {
          return lang.roomStateRoomAvatarUrlOtherChanged(senderName);
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomAvatarUrlYouSet;
        } else {
          return lang.roomStateRoomAvatarUrlOtherSet(senderName);
        }
      case 'Unset':
        if (isMe) {
          return lang.roomStateRoomAvatarUrlYouUnset;
        } else {
          return lang.roomStateRoomAvatarUrlOtherUnset(senderName);
        }
    }
    return null;
  }

  String getMessageOnRoomCreate(L10n lang, bool isMe, String senderName) {
    if (isMe) {
      return lang.roomStateRoomCreateYou;
    } else {
      return lang.roomStateRoomCreateOther(senderName);
    }
  }

  String? getMessageOnRoomEncryption(L10n lang, bool isMe, String senderName) {
    final content = item.roomEncryptionContent();
    if (content == null) {
      _log.severe('failed to get content of room encryption change');
      return null;
    }
    switch (content.algorithmChange()) {
      case 'Changed':
        final newVal = content.algorithmNewVal();
        final oldVal = content.algorithmOldVal() ?? '';
        if (isMe) {
          return lang.roomStateRoomEncryptionAlgorithmYouChanged(
            oldVal,
            newVal,
          );
        } else {
          return lang.roomStateRoomEncryptionAlgorithmOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.algorithmNewVal();
        if (isMe) {
          return lang.roomStateRoomEncryptionAlgorithmYouSet(newVal);
        } else {
          return lang.roomStateRoomEncryptionAlgorithmOtherSet(
            senderName,
            newVal,
          );
        }
    }
    return null;
  }

  String? getMessageOnRoomGuestAccess(L10n lang, bool isMe, String senderName) {
    final content = item.roomGuestAccessContent();
    if (content == null) {
      _log.severe('failed to get content of room guest access change');
      return null;
    }
    switch (content.change()) {
      case 'Changed':
        final newVal = content.newVal();
        final oldVal = content.oldVal() ?? '';
        if (isMe) {
          return lang.roomStateRoomGuestAccessYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomGuestAccessOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.newVal();
        if (isMe) {
          return lang.roomStateRoomGuestAccessYouSet(newVal);
        } else {
          return lang.roomStateRoomGuestAccessOtherSet(senderName, newVal);
        }
    }
    return null;
  }

  String? getMessageOnRoomHistoryVisibility(
    L10n lang,
    bool isMe,
    String senderName,
  ) {
    final content = item.roomHistoryVisibilityContent();
    if (content == null) {
      _log.severe('failed to get content of room history visibility change');
      return null;
    }
    switch (content.change()) {
      case 'Changed':
        final newVal = content.newVal();
        final oldVal = content.oldVal() ?? '';
        if (isMe) {
          return lang.roomStateRoomHistoryVisibilityYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomHistoryVisibilityOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.newVal();
        if (isMe) {
          return lang.roomStateRoomHistoryVisibilityYouSet(newVal);
        } else {
          return lang.roomStateRoomHistoryVisibilityOtherSet(
            senderName,
            newVal,
          );
        }
    }
    return null;
  }

  String? getMessageOnRoomJoinRules(L10n lang, bool isMe, String senderName) {
    final content = item.roomJoinRulesContent();
    if (content == null) {
      _log.severe('failed to get content of room join rules change');
      return null;
    }
    switch (content.change()) {
      case 'Changed':
        final newVal = content.newVal();
        final oldVal = content.oldVal() ?? '';
        if (isMe) {
          return lang.roomStateRoomJoinRulesYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomJoinRulesOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.newVal();
        if (isMe) {
          return lang.roomStateRoomJoinRulesYouSet(newVal);
        } else {
          return lang.roomStateRoomJoinRulesOtherSet(senderName, newVal);
        }
    }
    return null;
  }

  String? getMessageOnRoomName(L10n lang, bool isMe, String senderName) {
    final content = item.roomNameContent();
    if (content == null) {
      _log.severe('failed to get content of room name change');
      return null;
    }
    switch (content.change()) {
      case 'Changed':
        final newVal = content.newVal();
        final oldVal = content.oldVal() ?? '';
        if (isMe) {
          return lang.roomStateRoomNameYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomNameOtherChanged(senderName, oldVal, newVal);
        }
      case 'Set':
        final newVal = content.newVal();
        if (isMe) {
          return lang.roomStateRoomNameYouSet(newVal);
        } else {
          return lang.roomStateRoomNameOtherSet(senderName, newVal);
        }
    }
    return null;
  }

  String? getMessageOnRoomPinnedEvents(
    L10n lang,
    bool isMe,
    String senderName,
  ) {
    final content = item.roomPinnedEventsContent();
    if (content == null) {
      _log.severe('failed to get content of room pinned events change');
      return null;
    }
    switch (content.change()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomPinnedEventsYouChanged;
        } else {
          return lang.roomStateRoomPinnedEventsOtherChanged(senderName);
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomPinnedEventsYouSet;
        } else {
          return lang.roomStateRoomPinnedEventsOtherSet(senderName);
        }
    }
    return null;
  }

  String? getMessageOnRoomPowerLevels(L10n lang, bool isMe, String senderName) {
    final content = item.roomPowerLevelsContent();
    if (content == null) {
      _log.severe('failed to get content of room power levels change');
      return null;
    }
    switch (content.banChange()) {
      case 'Changed':
        final newVal = content.banNewVal();
        final oldVal = content.banOldVal() ?? -1;
        if (isMe) {
          return lang.roomStateRoomPowerLevelsBanYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomPowerLevelsBanOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.banNewVal();
        if (isMe) {
          return lang.roomStateRoomPowerLevelsBanYouSet(newVal);
        } else {
          return lang.roomStateRoomPowerLevelsBanOtherSet(senderName, newVal);
        }
    }
    switch (content.eventsChange('m.policy.rule.room')) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouChanged(
            'm.policy.rule.room',
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherChanged(
            senderName,
            'm.policy.rule.room',
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouSet(
            'm.policy.rule.room',
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherSet(
            senderName,
            'm.policy.rule.room',
          );
        }
    }
    switch (content.eventsChange('m.policy.rule.server')) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouChanged(
            'm.policy.rule.server',
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherChanged(
            senderName,
            'm.policy.rule.server',
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouSet(
            'm.policy.rule.server',
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherSet(
            senderName,
            'm.policy.rule.server',
          );
        }
    }
    switch (content.eventsChange('m.policy.rule.user')) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouChanged(
            'm.policy.rule.user',
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherChanged(
            senderName,
            'm.policy.rule.user',
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouSet(
            'm.policy.rule.user',
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherSet(
            senderName,
            'm.policy.rule.user',
          );
        }
    }
    switch (content.eventsChange('m.room.avatar')) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouChanged('m.room.avatar');
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherChanged(
            senderName,
            'm.room.avatar',
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouSet('m.room.avatar');
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherSet(
            senderName,
            'm.room.avatar',
          );
        }
    }
    switch (content.eventsChange('m.room.encryption')) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouChanged(
            'm.room.encryption',
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherChanged(
            senderName,
            'm.room.encryption',
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouSet('m.room.encryption');
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherSet(
            senderName,
            'm.room.encryption',
          );
        }
    }
    switch (content.eventsChange('m.room.guest_access')) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouChanged(
            'm.room.guest_access',
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherChanged(
            senderName,
            'm.room.guest_access',
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouSet(
            'm.room.guest_access',
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherSet(
            senderName,
            'm.room.guest_access',
          );
        }
    }
    switch (content.eventsChange('m.room.history_visibility')) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouChanged(
            'm.room.history_visibility',
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherChanged(
            senderName,
            'm.room.history_visibility',
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouSet(
            'm.room.history_visibility',
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherSet(
            senderName,
            'm.room.history_visibility',
          );
        }
    }
    switch (content.eventsChange('m.room.join_rules')) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouChanged(
            'm.room.join_rules',
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherChanged(
            senderName,
            'm.room.join_rules',
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouSet('m.room.join_rules');
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherSet(
            senderName,
            'm.room.join_rules',
          );
        }
    }
    switch (content.eventsChange('m.room.name')) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouChanged('m.room.name');
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherChanged(
            senderName,
            'm.room.name',
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouSet('m.room.name');
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherSet(
            senderName,
            'm.room.name',
          );
        }
    }
    switch (content.eventsChange('m.room.pinned_events')) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouChanged(
            'm.room.pinned_events',
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherChanged(
            senderName,
            'm.room.pinned_events',
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouSet(
            'm.room.pinned_events',
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherSet(
            senderName,
            'm.room.pinned_events',
          );
        }
    }
    switch (content.eventsChange('m.room.server_acl')) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouChanged(
            'm.room.server_acl',
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherChanged(
            senderName,
            'm.room.server_acl',
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouSet('m.room.server_acl');
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherSet(
            senderName,
            'm.room.server_acl',
          );
        }
    }
    switch (content.eventsChange('m.room.third_party_invite')) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouChanged(
            'm.room.third_party_invite',
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherChanged(
            senderName,
            'm.room.third_party_invite',
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouSet(
            'm.room.third_party_invite',
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherSet(
            senderName,
            'm.room.third_party_invite',
          );
        }
    }
    switch (content.eventsChange('m.room.tombstone')) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouChanged(
            'm.room.tombstone',
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherChanged(
            senderName,
            'm.room.tombstone',
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouSet('m.room.tombstone');
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherSet(
            senderName,
            'm.room.tombstone',
          );
        }
    }
    switch (content.eventsChange('m.room.topic')) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouChanged('m.room.topic');
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherChanged(
            senderName,
            'm.room.topic',
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouSet('m.room.topic');
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherSet(
            senderName,
            'm.room.topic',
          );
        }
    }
    switch (content.eventsDefaultChange()) {
      case 'Changed':
        final newVal = content.eventsDefaultNewVal();
        final oldVal = content.eventsDefaultOldVal() ?? -1;
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsDefaultYouChanged(
            oldVal,
            newVal,
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsDefaultOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.eventsDefaultNewVal();
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsDefaultYouSet(newVal);
        } else {
          return lang.roomStateRoomPowerLevelsEventsDefaultOtherSet(
            senderName,
            newVal,
          );
        }
    }
    switch (content.inviteChange()) {
      case 'Changed':
        final newVal = content.inviteNewVal();
        final oldVal = content.inviteOldVal() ?? -1;
        if (isMe) {
          return lang.roomStateRoomPowerLevelsInviteYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomPowerLevelsInviteOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.inviteNewVal();
        if (isMe) {
          return lang.roomStateRoomPowerLevelsInviteYouSet(newVal);
        } else {
          return lang.roomStateRoomPowerLevelsInviteOtherSet(
            senderName,
            newVal,
          );
        }
    }
    switch (content.kickChange()) {
      case 'Changed':
        final newVal = content.kickNewVal();
        final oldVal = content.kickOldVal() ?? -1;
        if (isMe) {
          return lang.roomStateRoomPowerLevelsKickYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomPowerLevelsKickOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.kickNewVal();
        if (isMe) {
          return lang.roomStateRoomPowerLevelsKickYouSet(newVal);
        } else {
          return lang.roomStateRoomPowerLevelsKickOtherSet(senderName, newVal);
        }
    }
    switch (content.notificationsChange()) {
      case 'Changed':
        final newVal = content.notificationsNewVal();
        final oldVal = content.notificationsOldVal() ?? -1;
        if (isMe) {
          return lang.roomStateRoomPowerLevelsNotificationYouChanged(
            oldVal,
            newVal,
          );
        } else {
          return lang.roomStateRoomPowerLevelsNotificationOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.notificationsNewVal();
        if (isMe) {
          return lang.roomStateRoomPowerLevelsNotificationYouSet(newVal);
        } else {
          return lang.roomStateRoomPowerLevelsNotificationOtherSet(
            senderName,
            newVal,
          );
        }
    }
    switch (content.redactChange()) {
      case 'Changed':
        final newVal = content.redactNewVal();
        final oldVal = content.redactOldVal() ?? -1;
        if (isMe) {
          return lang.roomStateRoomPowerLevelsRedactYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomPowerLevelsRedactOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.redactNewVal();
        if (isMe) {
          return lang.roomStateRoomPowerLevelsRedactYouSet(newVal);
        } else {
          return lang.roomStateRoomPowerLevelsRedactOtherSet(
            senderName,
            newVal,
          );
        }
    }
    switch (content.stateDefaultChange()) {
      case 'Changed':
        final newVal = content.stateDefaultNewVal();
        final oldVal = content.stateDefaultOldVal() ?? -1;
        if (isMe) {
          return lang.roomStateRoomPowerLevelsStateDefaultYouChanged(
            oldVal,
            newVal,
          );
        } else {
          return lang.roomStateRoomPowerLevelsStateDefaultOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.stateDefaultNewVal();
        if (isMe) {
          return lang.roomStateRoomPowerLevelsStateDefaultYouSet(newVal);
        } else {
          return lang.roomStateRoomPowerLevelsStateDefaultOtherSet(
            senderName,
            newVal,
          );
        }
    }
    switch (content.usersChange()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsUsersYouChanged;
        } else {
          return lang.roomStateRoomPowerLevelsUsersOtherChanged(senderName);
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsUsersYouSet;
        } else {
          return lang.roomStateRoomPowerLevelsUsersOtherSet(senderName);
        }
    }
    switch (content.usersDefaultChange()) {
      case 'Changed':
        final newVal = content.usersDefaultNewVal();
        final oldVal = content.usersDefaultOldVal() ?? -1;
        if (isMe) {
          return lang.roomStateRoomPowerLevelsUsersDefaultYouChanged(
            oldVal,
            newVal,
          );
        } else {
          return lang.roomStateRoomPowerLevelsUsersDefaultOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.usersDefaultNewVal();
        if (isMe) {
          return lang.roomStateRoomPowerLevelsUsersDefaultYouSet(newVal);
        } else {
          return lang.roomStateRoomPowerLevelsUsersDefaultOtherSet(
            senderName,
            newVal,
          );
        }
    }
    return null;
  }

  String? getMessageOnRoomServerAcl(L10n lang, bool isMe, String senderName) {
    final content = item.roomServerAclContent();
    if (content == null) {
      _log.severe('failed to get content of room server acl change');
      return null;
    }
    switch (content.allowIpLiteralsChange()) {
      case 'Changed':
        final newVal = content.allowIpLiteralsNewVal();
        final oldVal = content.allowIpLiteralsOldVal() ?? false;
        if (isMe) {
          return lang.roomStateRoomServerAclAllowIpLiteralsYouChanged(
            oldVal,
            newVal,
          );
        } else {
          return lang.roomStateRoomServerAclAllowIpLiteralsOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.allowIpLiteralsNewVal();
        if (isMe) {
          return lang.roomStateRoomServerAclAllowIpLiteralsYouSet(newVal);
        } else {
          return lang.roomStateRoomServerAclAllowIpLiteralsOtherSet(
            senderName,
            newVal,
          );
        }
    }
    switch (content.allowChange()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomServerAclAllowYouChanged;
        } else {
          return lang.roomStateRoomServerAclAllowOtherChanged(senderName);
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomServerAclAllowYouSet;
        } else {
          return lang.roomStateRoomServerAclAllowOtherSet(senderName);
        }
    }
    switch (content.denyChange()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomServerAclDenyYouChanged;
        } else {
          return lang.roomStateRoomServerAclDenyOtherChanged(senderName);
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomServerAclDenyYouSet;
        } else {
          return lang.roomStateRoomServerAclDenyOtherSet(senderName);
        }
    }
    return null;
  }

  String? getMessageOnRoomTombstone(L10n lang, bool isMe, String senderName) {
    final content = item.roomTombstoneContent();
    if (content == null) {
      _log.severe('failed to get content of room tombstone change');
      return null;
    }
    switch (content.bodyChange()) {
      case 'Changed':
        final newVal = content.bodyNewVal();
        final oldVal = content.bodyOldVal() ?? '';
        if (isMe) {
          return lang.roomStateRoomTombstoneBodyYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomTombstoneBodyOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.bodyNewVal();
        if (isMe) {
          return lang.roomStateRoomTombstoneBodyYouSet(newVal);
        } else {
          return lang.roomStateRoomTombstoneBodyOtherSet(senderName, newVal);
        }
    }
    switch (content.replacementRoomChange()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomTombstoneReplacementRoomYouChanged;
        } else {
          return lang.roomStateRoomTombstoneReplacementRoomOtherChanged(
            senderName,
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomTombstoneReplacementRoomYouSet;
        } else {
          return lang.roomStateRoomTombstoneReplacementRoomOtherSet(senderName);
        }
    }
    return null;
  }

  String? getMessageOnRoomTopic(L10n lang, bool isMe, String senderName) {
    final content = item.roomTopicContent();
    if (content == null) {
      _log.severe('failed to get content of room topic change');
      return null;
    }
    switch (content.change()) {
      case 'Changed':
        final newVal = content.newVal();
        final oldVal = content.oldVal() ?? '';
        if (isMe) {
          return lang.roomStateRoomTopicYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomTopicOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.newVal();
        if (isMe) {
          return lang.roomStateRoomTopicYouSet(newVal);
        } else {
          return lang.roomStateRoomTopicOtherSet(senderName, newVal);
        }
    }
    return null;
  }

  String? getMessageOnSpaceChild(L10n lang, bool isMe, String senderName) {
    final content = item.spaceChildContent();
    if (content == null) {
      _log.severe('failed to get content of space child change');
      return null;
    }
    switch (content.viaChange()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateSpaceChildViaYouChanged;
        } else {
          return lang.roomStateSpaceChildViaOtherChanged(senderName);
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateSpaceChildViaYouSet;
        } else {
          return lang.roomStateSpaceChildViaOtherSet(senderName);
        }
    }
    switch (content.orderChange()) {
      case 'Changed':
        final newVal = content.orderNewVal() ?? '';
        final oldVal = content.orderOldVal() ?? '';
        if (isMe) {
          return lang.roomStateSpaceChildOrderYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateSpaceChildOrderOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.orderNewVal() ?? '';
        if (isMe) {
          return lang.roomStateSpaceChildOrderYouSet(newVal);
        } else {
          return lang.roomStateSpaceChildOrderOtherSet(senderName, newVal);
        }
      case 'Unset':
        if (isMe) {
          return lang.roomStateSpaceChildOrderYouUnset;
        } else {
          return lang.roomStateSpaceChildOrderOtherUnset(senderName);
        }
    }
    switch (content.suggestedChange()) {
      case 'Changed':
        final newVal = content.suggestedNewVal();
        final oldVal = content.suggestedOldVal() ?? false;
        if (isMe) {
          return lang.roomStateSpaceChildSuggestedYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateSpaceChildSuggestedOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.suggestedNewVal();
        if (isMe) {
          return lang.roomStateSpaceChildSuggestedYouSet(newVal);
        } else {
          return lang.roomStateSpaceChildSuggestedOtherSet(senderName, newVal);
        }
    }
    return null;
  }

  String? getMessageOnSpaceParent(L10n lang, bool isMe, String senderName) {
    final content = item.spaceParentContent();
    if (content == null) {
      _log.severe('failed to get content of space parent change');
      return null;
    }
    switch (content.viaChange()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateSpaceParentViaYouChanged;
        } else {
          return lang.roomStateSpaceParentViaOtherChanged(senderName);
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateSpaceParentViaYouSet;
        } else {
          return lang.roomStateSpaceParentViaOtherSet(senderName);
        }
    }
    switch (content.canonicalChange()) {
      case 'Changed':
        final newVal = content.canonicalNewVal();
        final oldVal = content.canonicalOldVal() ?? false;
        if (isMe) {
          return lang.roomStateSpaceParentCanonicalYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateSpaceParentCanonicalOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateSpaceParentViaYouSet;
        } else {
          return lang.roomStateSpaceParentViaOtherSet(senderName);
        }
    }
    return null;
  }
}
