import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show MembershipContent, TimelineEventItem;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat_ng::widgets::member_update');

class MemberUpdateEvent extends ConsumerWidget {
  final String roomId;
  final TimelineEventItem item;

  const MemberUpdateEvent({
    super.key,
    required this.roomId,
    required this.item,
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
    final myId = ref.watch(myUserIdStrProvider);
    final senderId = item.sender();
    final senderName =
        ref
            .watch(
              memberDisplayNameProvider((roomId: roomId, userId: senderId)),
            )
            .valueOrNull ??
        simplifyUserId(senderId) ??
        senderId;
    MembershipContent? content = item.membershipContent();
    if (content == null) {
      _log.severe('failed to get content of membership change');
      return null;
    }
    final userId = content.userId().toString();
    final userName =
        ref
            .watch(memberDisplayNameProvider((roomId: roomId, userId: userId)))
            .valueOrNull ??
        simplifyUserId(userId) ??
        userId;
    final lang = L10n.of(context);
    return switch (content.change()) {
      'joined' => getMessageOnJoined(lang, myId, userId, userName),
      'left' => getMessageOnLeft(lang, myId, userId, userName),
      'banned' => getMessageOnBanned(
        lang,
        myId,
        senderId,
        senderName,
        userId,
        userName,
      ),
      'unbanned' => getMessageOnUnbanned(
        lang,
        myId,
        senderId,
        senderName,
        userId,
        userName,
      ),
      'kicked' => getMessageOnKicked(
        lang,
        myId,
        senderId,
        senderName,
        userId,
        userName,
      ),
      'invited' => getMessageOnInvited(
        lang,
        myId,
        senderId,
        senderName,
        userId,
        userName,
      ),
      'kickedAndBanned' => getMessageOnKickedAndBanned(
        lang,
        myId,
        senderId,
        senderName,
        userId,
        userName,
      ),
      'invitationAccepted' => getMessageOnInvitationAccepted(
        lang,
        myId,
        userId,
        userName,
      ),
      'invitationRejected' => getMessageOnInvitationRejected(
        lang,
        myId,
        userId,
        userName,
      ),
      'invitationRevoked' => getMessageOnInvitationRevoked(
        lang,
        myId,
        userId,
        userName,
      ),
      'knocked' => getMessageOnKnocked(
        lang,
        myId,
        senderId,
        senderName,
        userId,
        userName,
      ),
      'knockAccepted' => getMessageOnKnockAccepted(
        lang,
        myId,
        userId,
        userName,
      ),
      'knockRetracted' => getMessageOnKnockRetracted(
        lang,
        myId,
        userId,
        userName,
      ),
      'knockDenied' => getMessageOnKnockDenied(lang, myId, userId, userName),
      _ => null,
    };
  }

  String getMessageOnJoined(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatMembershipYouJoined;
    } else {
      return lang.chatMembershipOtherJoined(userName);
    }
  }

  String getMessageOnLeft(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatMembershipYouLeft;
    } else {
      return lang.chatMembershipOtherLeft(userName);
    }
  }

  String getMessageOnBanned(
    L10n lang,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    if (senderId == myId) {
      return lang.chatMembershipYouBannedOther(userName);
    } else if (userId == myId) {
      return lang.chatMembershipOtherBannedYou(senderName);
    } else {
      return lang.chatMembershipOtherBannedOther(senderName, userName);
    }
  }

  String getMessageOnUnbanned(
    L10n lang,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    if (senderId == myId) {
      return lang.chatMembershipYouUnbannedOther(userName);
    } else if (userId == myId) {
      return lang.chatMembershipOtherUnbannedYou(senderName);
    } else {
      return lang.chatMembershipOtherUnbannedOther(senderName, userName);
    }
  }

  String getMessageOnKicked(
    L10n lang,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    if (senderId == myId) {
      return lang.chatMembershipYouKickedOther(userName);
    } else if (userId == myId) {
      return lang.chatMembershipOtherKickedYou(senderName);
    } else {
      return lang.chatMembershipOtherKickedOther(senderName, userName);
    }
  }

  String getMessageOnInvited(
    L10n lang,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    if (senderId == myId) {
      return lang.chatMembershipYouInvitedOther(userName);
    } else if (userId == myId) {
      return lang.chatMembershipOtherInvitedYou(senderName);
    } else {
      return lang.chatMembershipOtherInvitedOther(senderName, userName);
    }
  }

  String getMessageOnKickedAndBanned(
    L10n lang,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    if (senderId == myId) {
      return lang.chatMembershipYouKickedAndBannedOther(userName);
    } else if (userId == myId) {
      return lang.chatMembershipOtherKickedAndBannedYou(senderName);
    } else {
      return lang.chatMembershipOtherKickedAndBannedOther(senderName, userName);
    }
  }

  String getMessageOnInvitationAccepted(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatMembershipInvitationYouAccepted;
    } else {
      return lang.chatMembershipInvitationOtherAccepted(userName);
    }
  }

  String getMessageOnInvitationRejected(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatMembershipInvitationYouRejected;
    } else {
      return lang.chatMembershipInvitationOtherRejected(userName);
    }
  }

  String getMessageOnInvitationRevoked(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatMembershipInvitationYouRevoked;
    } else {
      return lang.chatMembershipInvitationOtherRevoked(userName);
    }
  }

  String getMessageOnKnocked(
    L10n lang,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    if (senderId == myId) {
      return lang.chatMembershipYouKnockedOther(userName);
    } else if (userId == myId) {
      return lang.chatMembershipOtherKnockedYou(senderName);
    } else {
      return lang.chatMembershipOtherKnockedOther(senderName, userName);
    }
  }

  String getMessageOnKnockAccepted(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatMembershipKnockYouAccepted;
    } else {
      return lang.chatMembershipKnockOtherAccepted(userName);
    }
  }

  String getMessageOnKnockRetracted(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatMembershipKnockYouRetracted;
    } else {
      return lang.chatMembershipKnockOtherRetracted(userName);
    }
  }

  String getMessageOnKnockDenied(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatMembershipKnockYouDenied;
    } else {
      return lang.chatMembershipKnockOtherDenied(userName);
    }
  }
}
