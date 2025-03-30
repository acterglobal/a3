import 'package:acter/common/extensions/options.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

String? getStateOnPolicyRuleRoom(
  L10n lang,
  TimelineEventItem item,
  String myId,
  String senderId,
  String senderName,
) {
  final content = item.policyRuleRoom();
  if (content == null) return null;
  final result = [];
  switch (content.entityChange()) {
    case 'Changed':
      final newVal = content.entityNewVal();
      final oldVal = content.entityOldVal().expect(
        'failed to get old val in entity changed of policy rule room',
      );
      if (senderId == myId) {
        result.add(
          lang.roomStatePolicyRuleRoomEntityYouChanged(newVal, oldVal),
        );
      } else {
        result.add(
          lang.roomStatePolicyRuleRoomEntityOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.entityNewVal();
      if (senderId == myId) {
        result.add(lang.roomStatePolicyRuleRoomEntityYouSet(newVal));
      } else {
        result.add(
          lang.roomStatePolicyRuleRoomEntityOtherSet(newVal, senderName),
        );
      }
      break;
  }
  switch (content.reasonChange()) {
    case 'Changed':
      final newVal = content.reasonNewVal();
      final oldVal = content.reasonOldVal().expect(
        'failed to get old val in reason changed of policy rule room',
      );
      if (senderId == myId) {
        result.add(
          lang.roomStatePolicyRuleRoomReasonYouChanged(newVal, oldVal),
        );
      } else {
        result.add(
          lang.roomStatePolicyRuleRoomReasonOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.reasonNewVal();
      if (senderId == myId) {
        result.add(lang.roomStatePolicyRuleRoomReasonYouSet(newVal));
      } else {
        result.add(
          lang.roomStatePolicyRuleRoomReasonOtherSet(newVal, senderName),
        );
      }
      break;
  }
  switch (content.recommendationChange()) {
    case 'Changed':
      final newVal = content.recommendationNewVal();
      final oldVal = content.recommendationOldVal().expect(
        'failed to get old val in recommendation changed of policy rule room',
      );
      if (senderId == myId) {
        result.add(
          lang.roomStatePolicyRuleRoomRecommendationYouChanged(newVal, oldVal),
        );
      } else {
        result.add(
          lang.roomStatePolicyRuleRoomRecommendationOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.recommendationNewVal();
      if (senderId == myId) {
        result.add(lang.roomStatePolicyRuleRoomRecommendationYouSet(newVal));
      } else {
        result.add(
          lang.roomStatePolicyRuleRoomRecommendationOtherSet(
            newVal,
            senderName,
          ),
        );
      }
      break;
  }
  if (result.isEmpty) return null;
  return result.join(', ');
}

String? getStateOnPolicyRuleServer(
  L10n lang,
  TimelineEventItem item,
  String myId,
  String senderId,
  String senderName,
) {
  final content = item.policyRuleServer();
  if (content == null) return null;
  final result = [];
  switch (content.entityChange()) {
    case 'Changed':
      final newVal = content.entityNewVal();
      final oldVal = content.entityOldVal().expect(
        'failed to get old val in entity changed of policy rule server',
      );
      if (senderId == myId) {
        result.add(
          lang.roomStatePolicyRuleServerEntityYouChanged(newVal, oldVal),
        );
      } else {
        result.add(
          lang.roomStatePolicyRuleServerEntityOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.entityNewVal();
      if (senderId == myId) {
        result.add(lang.roomStatePolicyRuleServerEntityYouSet(newVal));
      } else {
        result.add(
          lang.roomStatePolicyRuleServerEntityOtherSet(newVal, senderName),
        );
      }
      break;
  }
  switch (content.reasonChange()) {
    case 'Changed':
      final newVal = content.reasonNewVal();
      final oldVal = content.reasonOldVal().expect(
        'failed to get old val in reason changed of policy rule server',
      );
      if (senderId == myId) {
        result.add(
          lang.roomStatePolicyRuleServerReasonYouChanged(newVal, oldVal),
        );
      } else {
        result.add(
          lang.roomStatePolicyRuleServerReasonOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.reasonNewVal();
      if (senderId == myId) {
        result.add(lang.roomStatePolicyRuleServerReasonYouSet(newVal));
      } else {
        result.add(
          lang.roomStatePolicyRuleServerReasonOtherSet(newVal, senderName),
        );
      }
      break;
  }
  switch (content.recommendationChange()) {
    case 'Changed':
      final newVal = content.recommendationNewVal();
      final oldVal = content.recommendationOldVal().expect(
        'failed to get old val in recommendation changed of policy rule server',
      );
      if (senderId == myId) {
        result.add(
          lang.roomStatePolicyRuleServerRecommendationYouChanged(
            newVal,
            oldVal,
          ),
        );
      } else {
        result.add(
          lang.roomStatePolicyRuleServerRecommendationOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.recommendationNewVal();
      if (senderId == myId) {
        result.add(lang.roomStatePolicyRuleServerRecommendationYouSet(newVal));
      } else {
        result.add(
          lang.roomStatePolicyRuleServerRecommendationOtherSet(
            newVal,
            senderName,
          ),
        );
      }
      break;
  }
  if (result.isEmpty) return null;
  return result.join(', ');
}

String? getStateOnPolicyRuleUser(
  L10n lang,
  TimelineEventItem item,
  String myId,
  String senderId,
  String senderName,
) {
  final content = item.policyRuleUser();
  if (content == null) return null;
  final result = [];
  switch (content.entityChange()) {
    case 'Changed':
      final newVal = content.entityNewVal();
      final oldVal = content.entityOldVal().expect(
        'failed to get old val in entity changed of policy rule user',
      );
      if (senderId == myId) {
        result.add(
          lang.roomStatePolicyRuleUserEntityYouChanged(newVal, oldVal),
        );
      } else {
        result.add(
          lang.roomStatePolicyRuleUserEntityOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.entityNewVal();
      if (senderId == myId) {
        result.add(lang.roomStatePolicyRuleUserEntityYouSet(newVal));
      } else {
        result.add(
          lang.roomStatePolicyRuleUserEntityOtherSet(newVal, senderName),
        );
      }
      break;
  }
  switch (content.reasonChange()) {
    case 'Changed':
      final newVal = content.reasonNewVal();
      final oldVal = content.reasonOldVal().expect(
        'failed to get old val in reason changed of policy rule user',
      );
      if (senderId == myId) {
        result.add(
          lang.roomStatePolicyRuleUserReasonYouChanged(newVal, oldVal),
        );
      } else {
        result.add(
          lang.roomStatePolicyRuleUserReasonOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.reasonNewVal();
      if (senderId == myId) {
        result.add(lang.roomStatePolicyRuleUserReasonYouSet(newVal));
      } else {
        result.add(
          lang.roomStatePolicyRuleUserReasonOtherSet(newVal, senderName),
        );
      }
      break;
  }
  switch (content.recommendationChange()) {
    case 'Changed':
      final newVal = content.recommendationNewVal();
      final oldVal = content.recommendationOldVal().expect(
        'failed to get old val in recommendation changed of policy rule user',
      );
      if (senderId == myId) {
        result.add(
          lang.roomStatePolicyRuleUserRecommendationYouChanged(newVal, oldVal),
        );
      } else {
        result.add(
          lang.roomStatePolicyRuleUserRecommendationOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.recommendationNewVal();
      if (senderId == myId) {
        result.add(lang.roomStatePolicyRuleUserRecommendationYouSet(newVal));
      } else {
        result.add(
          lang.roomStatePolicyRuleUserRecommendationOtherSet(
            newVal,
            senderName,
          ),
        );
      }
      break;
  }
  if (result.isEmpty) return null;
  return result.join(', ');
}

String? getStateOnRoomAliases(
  L10n lang,
  TimelineEventItem item,
  String myId,
  String senderId,
  String senderName,
) {
  final content = item.roomAliases();
  if (content == null) return null;
  switch (content.change()) {
    case 'Changed':
      if (senderId == myId) {
        return lang.roomStateRoomAliasesYouChanged;
      } else {
        return lang.roomStateRoomAliasesOtherChanged(senderName);
      }
    case 'Set':
      if (senderId == myId) {
        return lang.roomStateRoomAliasesYouSet;
      } else {
        return lang.roomStateRoomAliasesOtherSet(senderName);
      }
    default:
      return null;
  }
}

String? getStateOnRoomAvatar(
  L10n lang,
  TimelineEventItem item,
  String myId,
  String senderId,
  String senderName,
) {
  final content = item.roomAvatar();
  if (content == null) return null;
  final result = [];
  switch (content.urlChange()) {
    case 'Changed':
      if (senderId == myId) {
        result.add(lang.roomStateRoomAvatarUrlYouChanged);
      } else {
        result.add(lang.roomStateRoomAvatarUrlOtherChanged(senderName));
      }
      break;
    case 'Set':
      if (senderId == myId) {
        result.add(lang.roomStateRoomAvatarUrlYouSet);
      } else {
        result.add(lang.roomStateRoomAvatarUrlOtherSet(senderName));
      }
      break;
    case 'Unset':
      if (senderId == myId) {
        result.add(lang.roomStateRoomAvatarUrlYouUnset);
      } else {
        result.add(lang.roomStateRoomAvatarUrlOtherUnset(senderName));
      }
      break;
  }
  if (result.isEmpty) return null;
  return result.join(', ');
}

String? getStateOnRoomCanonicalAlias(
  L10n lang,
  TimelineEventItem item,
  String myId,
  String senderId,
  String senderName,
) {
  final content = item.roomCanonicalAlias();
  if (content == null) return null;
  final result = [];
  switch (content.aliasChange()) {
    case 'Changed':
      final newVal = content.aliasNewVal().expect(
        'failed to get new val in alias changed of room canonical alias',
      );
      final oldVal = content.aliasOldVal().expect(
        'failed to get old val in alias changed of room canonical alias',
      );
      if (senderId == myId) {
        result.add(lang.roomStateRoomCanonicalAliasYouChanged(newVal, oldVal));
      } else {
        result.add(
          lang.roomStateRoomCanonicalAliasOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.aliasNewVal().expect(
        'failed to get new val in alias changed of room canonical alias',
      );
      if (senderId == myId) {
        result.add(lang.roomStateRoomCanonicalAliasYouSet(newVal));
      } else {
        result.add(
          lang.roomStateRoomCanonicalAliasOtherSet(newVal, senderName),
        );
      }
      break;
    case 'Unset':
      if (senderId == myId) {
        result.add(lang.roomStateRoomCanonicalAliasYouUnset);
      } else {
        result.add(lang.roomStateRoomCanonicalAliasOtherUnset(senderName));
      }
      break;
  }
  switch (content.altAliasesChange()) {
    case 'Changed':
      if (senderId == myId) {
        result.add(lang.roomStateRoomCanonicalAltAliasesYouChanged);
      } else {
        result.add(
          lang.roomStateRoomCanonicalAltAliasesOtherChanged(senderName),
        );
      }
      break;
    case 'Set':
      if (senderId == myId) {
        result.add(lang.roomStateRoomCanonicalAltAliasesYouSet);
      } else {
        result.add(lang.roomStateRoomCanonicalAltAliasesOtherSet(senderName));
      }
      break;
  }
  if (result.isEmpty) return null;
  return result.join(', ');
}

String getStateOnRoomCreate(
  L10n lang,
  String myId,
  String senderId,
  String senderName,
) {
  if (senderId == myId) {
    return lang.roomStateRoomCreateYou;
  } else {
    return lang.roomStateRoomCreateOther(senderName);
  }
}

String? getStateOnRoomEncryption(
  L10n lang,
  TimelineEventItem item,
  String myId,
  String senderId,
  String senderName,
) {
  final content = item.roomEncryption();
  if (content == null) return null;
  final result = [];
  switch (content.algorithmChange()) {
    case 'Changed':
      final newVal = content.algorithmNewVal();
      final oldVal = content.algorithmOldVal().expect(
        'failed to get old val in algorithm changed of room encryption',
      );
      if (senderId == myId) {
        result.add(
          lang.roomStateRoomEncryptionAlgorithmYouChanged(newVal, oldVal),
        );
      } else {
        result.add(
          lang.roomStateRoomEncryptionAlgorithmOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.algorithmNewVal();
      if (senderId == myId) {
        result.add(lang.roomStateRoomEncryptionAlgorithmYouSet(newVal));
      } else {
        result.add(
          lang.roomStateRoomEncryptionAlgorithmOtherSet(newVal, senderName),
        );
      }
      break;
  }
  if (result.isEmpty) return null;
  return result.join(', ');
}

String? getStateOnRoomGuestAccess(
  L10n lang,
  TimelineEventItem item,
  String myId,
  String senderId,
  String senderName,
) {
  final content = item.roomGuestAccess();
  if (content == null) return null;
  switch (content.change()) {
    case 'Changed':
      final newVal = content.newVal();
      final oldVal = content.oldVal().expect(
        'failed to get old val in changed of room guest access',
      );
      if (senderId == myId) {
        return lang.roomStateRoomGuestAccessYouChanged(newVal, oldVal);
      } else {
        return lang.roomStateRoomGuestAccessOtherChanged(
          newVal,
          oldVal,
          senderName,
        );
      }
    case 'Set':
      final newVal = content.newVal();
      if (senderId == myId) {
        return lang.roomStateRoomGuestAccessYouSet(newVal);
      } else {
        return lang.roomStateRoomGuestAccessOtherSet(newVal, senderName);
      }
    default:
      return null;
  }
}

String? getStateOnRoomHistoryVisibility(
  L10n lang,
  TimelineEventItem item,
  String myId,
  String senderId,
  String senderName,
) {
  final content = item.roomHistoryVisibility();
  if (content == null) return null;
  switch (content.change()) {
    case 'Changed':
      final newVal = content.newVal();
      final oldVal = content.oldVal().expect(
        'failed to get old val in changed of room history visibility',
      );
      if (senderId == myId) {
        return lang.roomStateRoomHistoryVisibilityYouChanged(newVal, oldVal);
      } else {
        return lang.roomStateRoomHistoryVisibilityOtherChanged(
          newVal,
          oldVal,
          senderName,
        );
      }
    case 'Set':
      final newVal = content.newVal();
      if (senderId == myId) {
        return lang.roomStateRoomHistoryVisibilityYouSet(newVal);
      } else {
        return lang.roomStateRoomHistoryVisibilityOtherSet(newVal, senderName);
      }
    default:
      return null;
  }
}

String? getStateOnRoomJoinRules(
  L10n lang,
  TimelineEventItem item,
  String myId,
  String senderId,
  String senderName,
) {
  final content = item.roomJoinRules();
  if (content == null) return null;
  switch (content.change()) {
    case 'Changed':
      final newVal = content.newVal();
      final oldVal = content.oldVal().expect(
        'failed to get old val in changed of room join rules',
      );
      if (senderId == myId) {
        return lang.roomStateRoomJoinRulesYouChanged(newVal, oldVal);
      } else {
        return lang.roomStateRoomJoinRulesOtherChanged(
          newVal,
          oldVal,
          senderName,
        );
      }
    case 'Set':
      final newVal = content.newVal();
      if (senderId == myId) {
        return lang.roomStateRoomJoinRulesYouSet(newVal);
      } else {
        return lang.roomStateRoomJoinRulesOtherSet(newVal, senderName);
      }
    default:
      return null;
  }
}

String? getStateOnRoomName(
  L10n lang,
  TimelineEventItem item,
  String myId,
  String senderId,
  String senderName,
) {
  final content = item.roomName();
  if (content == null) return null;
  switch (content.change()) {
    case 'Changed':
      final newVal = content.newVal();
      final oldVal = content.oldVal().expect(
        'failed to get old val in changed of room name',
      );
      if (senderId == myId) {
        return lang.roomStateRoomNameYouChanged(newVal, oldVal);
      } else {
        return lang.roomStateRoomNameOtherChanged(newVal, oldVal, senderName);
      }
    case 'Set':
      final newVal = content.newVal();
      if (senderId == myId) {
        return lang.roomStateRoomNameYouSet(newVal);
      } else {
        return lang.roomStateRoomNameOtherSet(newVal, senderName);
      }
    default:
      return null;
  }
}

String? getStateOnRoomPinnedEvents(
  L10n lang,
  TimelineEventItem item,
  String myId,
  String senderId,
  String senderName,
) {
  final content = item.roomPinnedEvents();
  if (content == null) return null;
  switch (content.change()) {
    case 'Changed':
      if (senderId == myId) {
        return lang.roomStateRoomPinnedEventsYouChanged;
      } else {
        return lang.roomStateRoomPinnedEventsOtherChanged(senderName);
      }
    case 'Set':
      if (senderId == myId) {
        return lang.roomStateRoomPinnedEventsYouSet;
      } else {
        return lang.roomStateRoomPinnedEventsOtherSet(senderName);
      }
    default:
      return null;
  }
}

String? getStateOnRoomPowerLevels(
  L10n lang,
  TimelineEventItem item,
  String myId,
  String senderId,
  String senderName,
) {
  final content = item.roomPowerLevels();
  if (content == null) return null;
  final result = [];
  switch (content.banChange()) {
    case 'Changed':
      final newVal = content.banNewVal();
      final oldVal = content.banOldVal().expect(
        'failed to get old val in ban changed of room power levels',
      );
      if (senderId == myId) {
        result.add(lang.roomStateRoomPowerLevelsBanYouChanged(newVal, oldVal));
      } else {
        result.add(
          lang.roomStateRoomPowerLevelsBanOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.banNewVal();
      if (senderId == myId) {
        result.add(lang.roomStateRoomPowerLevelsBanYouSet(newVal));
      } else {
        result.add(
          lang.roomStateRoomPowerLevelsBanOtherSet(newVal, senderName),
        );
      }
      break;
  }
  switch (content.eventsChange()) {
    case 'Changed':
      if (senderId == myId) {
        result.add(lang.roomStateRoomPowerLevelsEventsYouChanged);
      } else {
        result.add(lang.roomStateRoomPowerLevelsEventsOtherChanged(senderName));
      }
      break;
    case 'Set':
      if (senderId == myId) {
        result.add(lang.roomStateRoomPowerLevelsEventsYouSet);
      } else {
        result.add(lang.roomStateRoomPowerLevelsEventsOtherSet(senderName));
      }
      break;
  }
  switch (content.eventsDefaultChange()) {
    case 'Changed':
      final newVal = content.eventsDefaultNewVal();
      final oldVal = content.eventsDefaultOldVal().expect(
        'failed to get old val in events default changed of room power levels',
      );
      if (senderId == myId) {
        result.add(
          lang.roomStateRoomPowerLevelsEventsDefaultYouChanged(newVal, oldVal),
        );
      } else {
        result.add(
          lang.roomStateRoomPowerLevelsEventsDefaultOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.eventsDefaultNewVal();
      if (senderId == myId) {
        result.add(lang.roomStateRoomPowerLevelsEventsDefaultYouSet(newVal));
      } else {
        result.add(
          lang.roomStateRoomPowerLevelsEventsDefaultOtherSet(
            newVal,
            senderName,
          ),
        );
      }
      break;
  }
  switch (content.inviteChange()) {
    case 'Changed':
      final newVal = content.inviteNewVal();
      final oldVal = content.inviteOldVal().expect(
        'failed to get old val in invite changed of room power levels',
      );
      if (senderId == myId) {
        result.add(
          lang.roomStateRoomPowerLevelsInviteYouChanged(newVal, oldVal),
        );
      } else {
        result.add(
          lang.roomStateRoomPowerLevelsInviteOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.inviteNewVal();
      if (senderId == myId) {
        result.add(lang.roomStateRoomPowerLevelsInviteYouSet(newVal));
      } else {
        result.add(
          lang.roomStateRoomPowerLevelsInviteOtherSet(newVal, senderName),
        );
      }
      break;
  }
  switch (content.kickChange()) {
    case 'Changed':
      final newVal = content.kickNewVal();
      final oldVal = content.kickOldVal().expect(
        'failed to get old val in kick changed of room power levels',
      );
      if (senderId == myId) {
        result.add(lang.roomStateRoomPowerLevelsKickYouChanged(newVal, oldVal));
      } else {
        result.add(
          lang.roomStateRoomPowerLevelsKickOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.kickNewVal();
      if (senderId == myId) {
        result.add(lang.roomStateRoomPowerLevelsKickYouSet(newVal));
      } else {
        result.add(
          lang.roomStateRoomPowerLevelsKickOtherSet(newVal, senderName),
        );
      }
      break;
  }
  switch (content.notificationsChange()) {
    case 'Changed':
      final newVal = content.notificationsNewVal();
      final oldVal = content.notificationsOldVal().expect(
        'failed to get old val in notifications changed of room power levels',
      );
      if (senderId == myId) {
        result.add(
          lang.roomStateRoomPowerLevelsNotificationYouChanged(newVal, oldVal),
        );
      } else {
        result.add(
          lang.roomStateRoomPowerLevelsNotificationOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.notificationsNewVal();
      if (senderId == myId) {
        result.add(lang.roomStateRoomPowerLevelsNotificationYouSet(newVal));
      } else {
        result.add(
          lang.roomStateRoomPowerLevelsNotificationOtherSet(newVal, senderName),
        );
      }
      break;
  }
  switch (content.redactChange()) {
    case 'Changed':
      final newVal = content.redactNewVal();
      final oldVal = content.redactOldVal().expect(
        'failed to get old val in redact changed of room power levels',
      );
      if (senderId == myId) {
        result.add(
          lang.roomStateRoomPowerLevelsRedactYouChanged(newVal, oldVal),
        );
      } else {
        result.add(
          lang.roomStateRoomPowerLevelsRedactOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.redactNewVal();
      if (senderId == myId) {
        result.add(lang.roomStateRoomPowerLevelsRedactYouSet(newVal));
      } else {
        result.add(
          lang.roomStateRoomPowerLevelsRedactOtherSet(newVal, senderName),
        );
      }
      break;
  }
  switch (content.stateDefaultChange()) {
    case 'Changed':
      final newVal = content.stateDefaultNewVal();
      final oldVal = content.stateDefaultOldVal().expect(
        'failed to get old val in state default changed of room power levels',
      );
      if (senderId == myId) {
        result.add(
          lang.roomStateRoomPowerLevelsStateDefaultYouChanged(newVal, oldVal),
        );
      } else {
        result.add(
          lang.roomStateRoomPowerLevelsStateDefaultOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.stateDefaultNewVal();
      if (senderId == myId) {
        result.add(lang.roomStateRoomPowerLevelsStateDefaultYouSet(newVal));
      } else {
        result.add(
          lang.roomStateRoomPowerLevelsStateDefaultOtherSet(newVal, senderName),
        );
      }
      break;
  }
  switch (content.usersChange()) {
    case 'Changed':
      if (senderId == myId) {
        result.add(lang.roomStateRoomPowerLevelsUsersYouChanged);
      } else {
        result.add(lang.roomStateRoomPowerLevelsUsersOtherChanged(senderName));
      }
      break;
    case 'Set':
      if (senderId == myId) {
        result.add(lang.roomStateRoomPowerLevelsUsersYouSet);
      } else {
        result.add(lang.roomStateRoomPowerLevelsUsersOtherSet(senderName));
      }
      break;
  }
  switch (content.usersDefaultChange()) {
    case 'Changed':
      final newVal = content.usersDefaultNewVal();
      final oldVal = content.usersDefaultOldVal().expect(
        'failed to get old val in users default changed of room power levels',
      );
      if (senderId == myId) {
        result.add(
          lang.roomStateRoomPowerLevelsUsersDefaultYouChanged(newVal, oldVal),
        );
      } else {
        result.add(
          lang.roomStateRoomPowerLevelsUsersDefaultOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.usersDefaultNewVal();
      if (senderId == myId) {
        result.add(lang.roomStateRoomPowerLevelsUsersDefaultYouSet(newVal));
      } else {
        result.add(
          lang.roomStateRoomPowerLevelsUsersDefaultOtherSet(newVal, senderName),
        );
      }
      break;
  }
  if (result.isEmpty) return null;
  return result.join(', ');
}

String? getStateOnRoomServerAcl(
  L10n lang,
  TimelineEventItem item,
  String myId,
  String senderId,
  String senderName,
) {
  final content = item.roomServerAcl();
  if (content == null) return null;
  final result = [];
  switch (content.allowIpLiteralsChange()) {
    case 'Changed':
      final newVal = content.allowIpLiteralsNewVal();
      final oldVal = content.allowIpLiteralsOldVal().expect(
        'failed to get old val in allow ip literals changed of room server acl',
      );
      if (senderId == myId) {
        result.add(
          lang.roomStateRoomServerAclAllowIpLiteralsYouChanged(newVal, oldVal),
        );
      } else {
        result.add(
          lang.roomStateRoomServerAclAllowIpLiteralsOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.allowIpLiteralsNewVal();
      if (senderId == myId) {
        result.add(lang.roomStateRoomServerAclAllowIpLiteralsYouSet(newVal));
      } else {
        result.add(
          lang.roomStateRoomServerAclAllowIpLiteralsOtherSet(
            newVal,
            senderName,
          ),
        );
      }
      break;
  }
  switch (content.allowChange()) {
    case 'Changed':
      if (senderId == myId) {
        result.add(lang.roomStateRoomServerAclAllowYouChanged);
      } else {
        result.add(lang.roomStateRoomServerAclAllowOtherChanged(senderName));
      }
      break;
    case 'Set':
      if (senderId == myId) {
        result.add(lang.roomStateRoomServerAclAllowYouSet);
      } else {
        result.add(lang.roomStateRoomServerAclAllowOtherSet(senderName));
      }
      break;
  }
  switch (content.denyChange()) {
    case 'Changed':
      if (senderId == myId) {
        result.add(lang.roomStateRoomServerAclDenyYouChanged);
      } else {
        result.add(lang.roomStateRoomServerAclDenyOtherChanged(senderName));
      }
      break;
    case 'Set':
      if (senderId == myId) {
        result.add(lang.roomStateRoomServerAclDenyYouSet);
      } else {
        result.add(lang.roomStateRoomServerAclDenyOtherSet(senderName));
      }
      break;
  }
  if (result.isEmpty) return null;
  return result.join(', ');
}

String? getStateOnRoomThirdPartyInvite(
  L10n lang,
  TimelineEventItem item,
  String myId,
  String senderId,
  String senderName,
) {
  final content = item.roomThirdPartyInvite();
  if (content == null) return null;
  final result = [];
  switch (content.displayNameChange()) {
    case 'Changed':
      final newVal = content.displayNameNewVal();
      final oldVal = content.displayNameOldVal().expect(
        'failed to get old val in display name changed of room third party invite',
      );
      if (senderId == myId) {
        result.add(
          lang.roomStateRoomThirdPartyInviteDisplayNameYouChanged(
            newVal,
            oldVal,
          ),
        );
      } else {
        result.add(
          lang.roomStateRoomThirdPartyInviteDisplayNameOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.displayNameNewVal();
      if (senderId == myId) {
        result.add(lang.roomStateRoomThirdPartyInviteDisplayNameYouSet(newVal));
      } else {
        result.add(
          lang.roomStateRoomThirdPartyInviteDisplayNameOtherSet(
            newVal,
            senderName,
          ),
        );
      }
      break;
  }
  switch (content.keyValidityUrlChange()) {
    case 'Changed':
      if (senderId == myId) {
        result.add(lang.roomStateRoomThirdPartyInviteKeyValidityUrlYouChanged);
      } else {
        result.add(
          lang.roomStateRoomThirdPartyInviteKeyValidityUrlOtherChanged(
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      if (senderId == myId) {
        result.add(lang.roomStateRoomThirdPartyInviteKeyValidityUrlYouSet);
      } else {
        result.add(
          lang.roomStateRoomThirdPartyInviteKeyValidityUrlOtherSet(senderName),
        );
      }
      break;
  }
  switch (content.publicKeyChange()) {
    case 'Changed':
      if (senderId == myId) {
        result.add(lang.roomStateRoomThirdPartyInvitePublicKeyYouChanged);
      } else {
        result.add(
          lang.roomStateRoomThirdPartyInvitePublicKeyOtherChanged(senderName),
        );
      }
      break;
    case 'Set':
      if (senderId == myId) {
        result.add(lang.roomStateRoomThirdPartyInvitePublicKeyYouSet);
      } else {
        result.add(
          lang.roomStateRoomThirdPartyInvitePublicKeyOtherSet(senderName),
        );
      }
      break;
  }
  if (result.isEmpty) return null;
  return result.join(', ');
}

String? getStateOnRoomTombstone(
  L10n lang,
  TimelineEventItem item,
  String myId,
  String senderId,
  String senderName,
) {
  final content = item.roomTombstone();
  if (content == null) return null;
  final result = [];
  switch (content.bodyChange()) {
    case 'Changed':
      final newVal = content.bodyNewVal();
      final oldVal = content.bodyOldVal().expect(
        'failed to get old val in body changed of room tombstone',
      );
      if (senderId == myId) {
        result.add(lang.roomStateRoomTombstoneBodyYouChanged(newVal, oldVal));
      } else {
        result.add(
          lang.roomStateRoomTombstoneBodyOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.bodyNewVal();
      if (senderId == myId) {
        result.add(lang.roomStateRoomTombstoneBodyYouSet(newVal));
      } else {
        result.add(lang.roomStateRoomTombstoneBodyOtherSet(newVal, senderName));
      }
      break;
  }
  switch (content.replacementRoomChange()) {
    case 'Changed':
      if (senderId == myId) {
        result.add(lang.roomStateRoomTombstoneReplacementRoomYouChanged);
      } else {
        result.add(
          lang.roomStateRoomTombstoneReplacementRoomOtherChanged(senderName),
        );
      }
      break;
    case 'Set':
      if (senderId == myId) {
        result.add(lang.roomStateRoomTombstoneReplacementRoomYouSet);
      } else {
        result.add(
          lang.roomStateRoomTombstoneReplacementRoomOtherSet(senderName),
        );
      }
      break;
  }
  if (result.isEmpty) return null;
  return result.join(', ');
}

String? getStateOnRoomTopic(
  L10n lang,
  TimelineEventItem item,
  String myId,
  String senderId,
  String senderName,
) {
  final content = item.roomTopic();
  if (content == null) return null;
  switch (content.change()) {
    case 'Changed':
      final newVal = content.newVal();
      final oldVal = content.oldVal().expect(
        'failed to get old val in changed of room topic',
      );
      if (senderId == myId) {
        return lang.roomStateRoomTopicYouChanged(newVal, oldVal);
      } else {
        return lang.roomStateRoomTopicOtherChanged(newVal, oldVal, senderName);
      }
    case 'Set':
      final newVal = content.newVal();
      if (senderId == myId) {
        return lang.roomStateRoomTopicYouSet(newVal);
      } else {
        return lang.roomStateRoomTopicOtherSet(newVal, senderName);
      }
    default:
      return null;
  }
}

String? getStateOnSpaceChild(
  L10n lang,
  TimelineEventItem item,
  String myId,
  String senderId,
  String senderName,
) {
  final content = item.spaceChild();
  if (content == null) return null;
  final result = [];
  switch (content.viaChange()) {
    case 'Changed':
      if (senderId == myId) {
        result.add(lang.roomStateSpaceChildViaYouChanged);
      } else {
        result.add(lang.roomStateSpaceChildViaOtherChanged(senderName));
      }
      break;
    case 'Set':
      if (senderId == myId) {
        result.add(lang.roomStateSpaceChildViaYouSet);
      } else {
        result.add(lang.roomStateSpaceChildViaOtherSet(senderName));
      }
      break;
  }
  switch (content.orderChange()) {
    case 'Changed':
      final newVal = content.orderNewVal().expect(
        'failed to get new val in order changed of SpaceChild',
      );
      final oldVal = content.orderOldVal().expect(
        'failed to get old val in order changed of SpaceChild',
      );
      if (senderId == myId) {
        result.add(lang.roomStateSpaceChildOrderYouChanged(newVal, oldVal));
      } else {
        result.add(
          lang.roomStateSpaceChildOrderOtherChanged(newVal, oldVal, senderName),
        );
      }
      break;
    case 'Set':
      final newVal = content.orderNewVal().expect(
        'failed to get new val in order set of SpaceChild',
      );
      if (senderId == myId) {
        result.add(lang.roomStateSpaceChildOrderYouSet(newVal));
      } else {
        result.add(lang.roomStateSpaceChildOrderOtherSet(newVal, senderName));
      }
      break;
    case 'Unset':
      if (senderId == myId) {
        result.add(lang.roomStateSpaceChildOrderYouUnset);
      } else {
        result.add(lang.roomStateSpaceChildOrderOtherUnset(senderName));
      }
      break;
  }
  switch (content.suggestedChange()) {
    case 'Changed':
      final newVal = content.suggestedNewVal().expect(
        'failed to get new val in suggested changed of SpaceChild',
      );
      final oldVal = content.suggestedOldVal().expect(
        'failed to get old val in suggested changed of SpaceChild',
      );
      if (senderId == myId) {
        result.add(lang.roomStateSpaceChildSuggestedYouChanged(newVal, oldVal));
      } else {
        result.add(
          lang.roomStateSpaceChildSuggestedOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      final newVal = content.suggestedNewVal().expect(
        'failed to get new val in suggested set of SpaceChild',
      );
      if (senderId == myId) {
        result.add(lang.roomStateSpaceChildSuggestedYouSet(newVal));
      } else {
        result.add(
          lang.roomStateSpaceChildSuggestedOtherSet(newVal, senderName),
        );
      }
      break;
  }
  if (result.isEmpty) return null;
  return result.join(', ');
}

String? getStateOnSpaceParent(
  L10n lang,
  TimelineEventItem item,
  String myId,
  String senderId,
  String senderName,
) {
  final content = item.spaceParent();
  if (content == null) return null;
  final result = [];
  switch (content.viaChange()) {
    case 'Changed':
      if (senderId == myId) {
        result.add(lang.roomStateSpaceParentViaYouChanged);
      } else {
        result.add(lang.roomStateSpaceParentViaOtherChanged(senderName));
      }
      break;
    case 'Set':
      if (senderId == myId) {
        result.add(lang.roomStateSpaceParentViaYouSet);
      } else {
        result.add(lang.roomStateSpaceParentViaOtherSet(senderName));
      }
      break;
  }
  switch (content.canonicalChange()) {
    case 'Changed':
      final newVal = content.canonicalNewVal();
      final oldVal = content.canonicalOldVal().expect(
        'failed to get old val in canonical changed of SpaceParent',
      );
      if (senderId == myId) {
        result.add(
          lang.roomStateSpaceParentCanonicalYouChanged(newVal, oldVal),
        );
      } else {
        result.add(
          lang.roomStateSpaceParentCanonicalOtherChanged(
            newVal,
            oldVal,
            senderName,
          ),
        );
      }
      break;
    case 'Set':
      if (senderId == myId) {
        result.add(lang.roomStateSpaceParentViaYouSet);
      } else {
        result.add(lang.roomStateSpaceParentViaOtherSet(senderName));
      }
      break;
  }
  if (result.isEmpty) return null;
  return result.join(', ');
}

String? getStateOnMembershipChange(
  L10n lang,
  String change,
  String myId,
  String senderId,
  String senderName,
  String userId,
  String userName,
) {
  switch (change) {
    case 'None':
      if (userId == myId) {
        return lang.chatMembershipYouNone;
      } else {
        return lang.chatMembershipOtherNone(userName);
      }
    case 'Error':
      if (userId == myId) {
        return lang.chatMembershipYouError;
      } else {
        return lang.chatMembershipOtherError(userName);
      }
    case 'Joined':
      if (userId == myId) {
        return lang.chatMembershipYouJoined;
      } else {
        return lang.chatMembershipOtherJoined(userName);
      }
    case 'Left':
      if (userId == myId) {
        return lang.chatMembershipYouLeft;
      } else {
        return lang.chatMembershipOtherLeft(userName);
      }
    case 'Banned':
      if (senderId == myId) {
        return lang.chatMembershipYouBannedOther(userName);
      } else if (userId == myId) {
        return lang.chatMembershipOtherBannedYou(senderName);
      } else {
        return lang.chatMembershipOtherBannedOther(senderName, userName);
      }
    case 'Unbanned':
      if (senderId == myId) {
        return lang.chatMembershipYouUnbannedOther(userName);
      } else if (userId == myId) {
        return lang.chatMembershipOtherUnbannedYou(senderName);
      } else {
        return lang.chatMembershipOtherUnbannedOther(senderName, userName);
      }
    case 'Kicked':
      if (senderId == myId) {
        return lang.chatMembershipYouKickedOther(userName);
      } else if (userId == myId) {
        return lang.chatMembershipOtherKickedYou(senderName);
      } else {
        return lang.chatMembershipOtherKickedOther(senderName, userName);
      }
    case 'Invited':
      if (senderId == myId) {
        return lang.chatMembershipYouInvitedOther(userName);
      } else if (userId == myId) {
        return lang.chatMembershipOtherInvitedYou(senderName);
      } else {
        return lang.chatMembershipOtherInvitedOther(senderName, userName);
      }
    case 'KickedAndBanned':
      if (senderId == myId) {
        return lang.chatMembershipYouKickedAndBannedOther(userName);
      } else if (userId == myId) {
        return lang.chatMembershipOtherKickedAndBannedYou(senderName);
      } else {
        return lang.chatMembershipOtherKickedAndBannedOther(
          senderName,
          userName,
        );
      }
    case 'InvitationAccepted':
      if (userId == myId) {
        return lang.chatMembershipInvitationYouAccepted;
      } else {
        return lang.chatMembershipInvitationOtherAccepted(userName);
      }
    case 'InvitationRejected':
      if (userId == myId) {
        return lang.chatMembershipInvitationYouRejected;
      } else {
        return lang.chatMembershipInvitationOtherRejected(userName);
      }
    case 'InvitationRevoked':
      if (userId == myId) {
        return lang.chatMembershipInvitationYouRevoked;
      } else {
        return lang.chatMembershipInvitationOtherRevoked(userName);
      }
    case 'Knocked':
      if (senderId == myId) {
        return lang.chatMembershipYouKnockedOther(userName);
      } else if (userId == myId) {
        return lang.chatMembershipOtherKnockedYou(senderName);
      } else {
        return lang.chatMembershipOtherKnockedOther(senderName, userName);
      }
    case 'KnockAccepted':
      if (userId == myId) {
        return lang.chatMembershipKnockYouAccepted;
      } else {
        return lang.chatMembershipKnockOtherAccepted(userName);
      }
    case 'KnockRetracted':
      if (userId == myId) {
        return lang.chatMembershipKnockYouRetracted;
      } else {
        return lang.chatMembershipKnockOtherRetracted(userName);
      }
    case 'KnockDenied':
      if (userId == myId) {
        return lang.chatMembershipKnockYouDenied;
      } else {
        return lang.chatMembershipKnockOtherDenied(userName);
      }
    case 'NotImplemented':
      if (userId == myId) {
        return lang.chatMembershipYouNotImplemented;
      } else {
        return lang.chatMembershipOtherNotImplemented(userName);
      }
  }
  return null;
}

String? getStateOnProfileChange(
  L10n lang,
  Map<String, dynamic> metadata,
  String myId,
  String userId,
  String userName,
) {
  final result = [];
  switch (metadata['displayName']['change']) {
    case 'Changed':
      String newVal = metadata['displayName']['newVal'].expect(
        'failed to get new val in display name changed of profile change',
      );
      String oldVal = metadata['displayName']['oldVal'].expect(
        'failed to get old val in display name changed of profile change',
      );
      if (userId == myId) {
        result.add(lang.chatProfileDisplayNameYouChanged(newVal, oldVal));
      } else {
        result.add(
          lang.chatProfileDisplayNameOtherChanged(newVal, oldVal, userName),
        );
      }
      break;
    case 'Set':
      String newVal = metadata['displayName']['newVal'].expect(
        'failed to get new val in display name changed of profile change',
      );
      if (userId == myId) {
        result.add(lang.chatProfileDisplayNameYouSet(newVal));
      } else {
        result.add(lang.chatProfileDisplayNameOtherSet(newVal, userName));
      }
      break;
    case 'Unset':
      if (userId == myId) {
        result.add(lang.chatProfileDisplayNameYouUnset);
      } else {
        result.add(lang.chatProfileDisplayNameOtherUnset(userName));
      }
      break;
  }
  switch (metadata['avatarUrl']['change']) {
    case 'Changed':
      if (userId == myId) {
        result.add(lang.chatProfileAvatarUrlYouChanged);
      } else {
        result.add(lang.chatProfileAvatarUrlOtherChanged(userName));
      }
      break;
    case 'Set':
      if (userId == myId) {
        result.add(lang.chatProfileAvatarUrlYouSet);
      } else {
        result.add(lang.chatProfileAvatarUrlOtherSet(userName));
      }
      break;
    case 'Unset':
      if (userId == myId) {
        result.add(lang.chatProfileAvatarUrlYouUnset);
      } else {
        result.add(lang.chatProfileAvatarUrlOtherUnset(userName));
      }
      break;
  }
  if (result.isEmpty) return null;
  return result.join(', ');
}
