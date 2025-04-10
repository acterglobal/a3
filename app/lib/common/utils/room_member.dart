import 'package:acter/l10n/generated/l10n.dart';

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
    case 'joined':
      if (userId == myId) {
        return lang.chatMembershipYouJoined;
      } else {
        return lang.chatMembershipOtherJoined(userName);
      }
    case 'left':
      if (userId == myId) {
        return lang.chatMembershipYouLeft;
      } else {
        return lang.chatMembershipOtherLeft(userName);
      }
    case 'banned':
      if (senderId == myId) {
        return lang.chatMembershipYouBannedOther(userName);
      } else if (userId == myId) {
        return lang.chatMembershipOtherBannedYou(senderName);
      } else {
        return lang.chatMembershipOtherBannedOther(senderName, userName);
      }
    case 'unbanned':
      if (senderId == myId) {
        return lang.chatMembershipYouUnbannedOther(userName);
      } else if (userId == myId) {
        return lang.chatMembershipOtherUnbannedYou(senderName);
      } else {
        return lang.chatMembershipOtherUnbannedOther(senderName, userName);
      }
    case 'kicked':
      if (senderId == myId) {
        return lang.chatMembershipYouKickedOther(userName);
      } else if (userId == myId) {
        return lang.chatMembershipOtherKickedYou(senderName);
      } else {
        return lang.chatMembershipOtherKickedOther(senderName, userName);
      }
    case 'invited':
      if (senderId == myId) {
        return lang.chatMembershipYouInvitedOther(userName);
      } else if (userId == myId) {
        return lang.chatMembershipOtherInvitedYou(senderName);
      } else {
        return lang.chatMembershipOtherInvitedOther(senderName, userName);
      }
    case 'kickedAndBanned':
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
    case 'invitationAccepted':
      if (userId == myId) {
        return lang.chatMembershipInvitationYouAccepted;
      } else {
        return lang.chatMembershipInvitationOtherAccepted(userName);
      }
    case 'invitationRejected':
      if (userId == myId) {
        return lang.chatMembershipInvitationYouRejected;
      } else {
        return lang.chatMembershipInvitationOtherRejected(userName);
      }
    case 'invitationRevoked':
      if (userId == myId) {
        return lang.chatMembershipInvitationYouRevoked;
      } else {
        return lang.chatMembershipInvitationOtherRevoked(userName);
      }
    case 'knocked':
      if (senderId == myId) {
        return lang.chatMembershipYouKnockedOther(userName);
      } else if (userId == myId) {
        return lang.chatMembershipOtherKnockedYou(senderName);
      } else {
        return lang.chatMembershipOtherKnockedOther(senderName, userName);
      }
    case 'knockAccepted':
      if (userId == myId) {
        return lang.chatMembershipKnockYouAccepted;
      } else {
        return lang.chatMembershipKnockOtherAccepted(userName);
      }
    case 'knockRetracted':
      if (userId == myId) {
        return lang.chatMembershipKnockYouRetracted;
      } else {
        return lang.chatMembershipKnockOtherRetracted(userName);
      }
    case 'knockDenied':
      if (userId == myId) {
        return lang.chatMembershipKnockYouDenied;
      } else {
        return lang.chatMembershipKnockOtherDenied(userName);
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
  switch (metadata['displayName']['change']) {
    case 'Changed':
      String newVal = metadata['displayName']['newVal'].expect(
        'failed to get new val in display name changed of profile change',
      );
      String oldVal = metadata['displayName']['oldVal'].expect(
        'failed to get old val in display name changed of profile change',
      );
      if (userId == myId) {
        return lang.chatProfileDisplayNameYouChanged(newVal, oldVal);
      } else {
        return lang.chatProfileDisplayNameOtherChanged(
          newVal,
          oldVal,
          userName,
        );
      }
    case 'Set':
      String newVal = metadata['displayName']['newVal'].expect(
        'failed to get new val in display name changed of profile change',
      );
      if (userId == myId) {
        return lang.chatProfileDisplayNameYouSet(newVal);
      } else {
        return lang.chatProfileDisplayNameOtherSet(newVal, userName);
      }
    case 'Unset':
      if (userId == myId) {
        return lang.chatProfileDisplayNameYouUnset;
      } else {
        return lang.chatProfileDisplayNameOtherUnset(userName);
      }
  }
  switch (metadata['avatarUrl']['change']) {
    case 'Changed':
      if (userId == myId) {
        return lang.chatProfileAvatarUrlYouChanged;
      } else {
        return lang.chatProfileAvatarUrlOtherChanged(userName);
      }
    case 'Set':
      if (userId == myId) {
        return lang.chatProfileAvatarUrlYouSet;
      } else {
        return lang.chatProfileAvatarUrlOtherSet(userName);
      }
    case 'Unset':
      if (userId == myId) {
        return lang.chatProfileAvatarUrlYouUnset;
      } else {
        return lang.chatProfileAvatarUrlOtherUnset(userName);
      }
  }
  return null;
}
