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
  final bool isMe;
  final String roomId;
  final TimelineEventItem item;

  const MemberUpdateEvent({
    super.key,
    required this.isMe,
    required this.roomId,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    TextSpan? textSpan = buildStateWidget(context, ref, item);
    if (textSpan == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.only(left: 10, bottom: 5, right: 10),
      child: RichText(text: textSpan),
    );
  }

  TextSpan? buildStateWidget(
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
    return switch (content.change()) {
      'joined' => buildJoinedEventMessage(context, myId, userId, userName),
      'left' => buildLeftEventMessage(context, myId, userId, userName),
      'banned' => buildBannedEventMessage(
        context,
        myId,
        senderId,
        senderName,
        userId,
        userName,
      ),
      'unbanned' => buildUnbannedEventMessage(
        context,
        myId,
        senderId,
        senderName,
        userId,
        userName,
      ),
      'kicked' => buildKickedEventMessage(
        context,
        myId,
        senderId,
        senderName,
        userId,
        userName,
      ),
      'invited' => buildInvitedEventMessage(
        context,
        myId,
        senderId,
        senderName,
        userId,
        userName,
      ),
      'kickedAndBanned' => buildKickedAndBannedEventMessage(
        context,
        myId,
        senderId,
        senderName,
        userId,
        userName,
      ),
      'invitationAccepted' => buildInvitationAcceptedEventMessage(
        context,
        myId,
        userId,
        userName,
      ),
      'invitationRejected' => buildInvitationRejectedEventMessage(
        context,
        myId,
        userId,
        userName,
      ),
      'invitationRevoked' => buildInvitationRevokedEventMessage(
        context,
        myId,
        userId,
        userName,
      ),
      'knocked' => buildKnockedEventMessage(
        context,
        myId,
        senderId,
        senderName,
        userId,
        userName,
      ),
      'knockAccepted' => buildKnockAcceptedEventMessage(
        context,
        myId,
        userId,
        userName,
      ),
      'knockRetracted' => buildKnockRetractedEventMessage(
        context,
        myId,
        userId,
        userName,
      ),
      'knockDenied' => buildKnockDeniedEventMessage(
        context,
        myId,
        userId,
        userName,
      ),
      _ => null,
    };
  }

  TextSpan buildJoinedEventMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    if (userId == myId) {
      return TextSpan(
        text: lang.chatMembershipYouJoined,
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatMembershipOtherJoined(userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }

  TextSpan buildLeftEventMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    if (userId == myId) {
      return TextSpan(
        text: lang.chatMembershipYouLeft,
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatMembershipOtherLeft(userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }

  TextSpan buildBannedEventMessage(
    BuildContext context,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    if (senderId == myId) {
      return TextSpan(
        text: lang.chatMembershipYouBannedOther(userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else if (userId == myId) {
      return TextSpan(
        text: lang.chatMembershipOtherBannedYou(senderName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatMembershipOtherBannedOther(senderName, userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }

  TextSpan buildUnbannedEventMessage(
    BuildContext context,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    if (senderId == myId) {
      return TextSpan(
        text: lang.chatMembershipYouUnbannedOther(userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else if (userId == myId) {
      return TextSpan(
        text: lang.chatMembershipOtherUnbannedYou(senderName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatMembershipOtherUnbannedOther(senderName, userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }

  TextSpan buildKickedEventMessage(
    BuildContext context,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    if (senderId == myId) {
      return TextSpan(
        text: lang.chatMembershipYouKickedOther(userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else if (userId == myId) {
      return TextSpan(
        text: lang.chatMembershipOtherKickedYou(senderName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatMembershipOtherKickedOther(senderName, userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }

  TextSpan buildInvitedEventMessage(
    BuildContext context,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    if (senderId == myId) {
      return TextSpan(
        text: lang.chatMembershipYouInvitedOther(userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else if (userId == myId) {
      return TextSpan(
        text: lang.chatMembershipOtherInvitedYou(senderName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatMembershipOtherInvitedOther(senderName, userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }

  TextSpan buildKickedAndBannedEventMessage(
    BuildContext context,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    if (senderId == myId) {
      return TextSpan(
        text: lang.chatMembershipYouKickedAndBannedOther(userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else if (userId == myId) {
      return TextSpan(
        text: lang.chatMembershipOtherKickedAndBannedYou(senderName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatMembershipOtherKickedAndBannedOther(
          senderName,
          userName,
        ),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }

  TextSpan buildInvitationAcceptedEventMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    if (userId == myId) {
      return TextSpan(
        text: lang.chatMembershipInvitationYouAccepted,
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatMembershipInvitationOtherAccepted(userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }

  TextSpan buildInvitationRejectedEventMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    if (userId == myId) {
      return TextSpan(
        text: lang.chatMembershipInvitationYouRejected,
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatMembershipInvitationOtherRejected(userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }

  TextSpan buildInvitationRevokedEventMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    if (userId == myId) {
      return TextSpan(
        text: lang.chatMembershipInvitationYouRevoked,
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatMembershipInvitationOtherRevoked(userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }

  TextSpan buildKnockedEventMessage(
    BuildContext context,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    if (senderId == myId) {
      return TextSpan(
        text: lang.chatMembershipYouKnockedOther(userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else if (userId == myId) {
      return TextSpan(
        text: lang.chatMembershipOtherKnockedYou(senderName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatMembershipOtherKnockedOther(senderName, userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }

  TextSpan buildKnockAcceptedEventMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    if (userId == myId) {
      return TextSpan(
        text: lang.chatMembershipKnockYouAccepted,
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatMembershipKnockOtherAccepted(userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }

  TextSpan buildKnockRetractedEventMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    if (userId == myId) {
      return TextSpan(
        text: lang.chatMembershipKnockYouRetracted,
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatMembershipKnockOtherRetracted(userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }

  TextSpan buildKnockDeniedEventMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    if (userId == myId) {
      return TextSpan(
        text: lang.chatMembershipKnockYouDenied,
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatMembershipKnockOtherDenied(userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }
}
