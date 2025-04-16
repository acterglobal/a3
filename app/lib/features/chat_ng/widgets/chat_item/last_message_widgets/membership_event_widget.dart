import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MembershipEventWidget extends ConsumerWidget {
  final String roomId;
  final TimelineEventItem eventItem;

  const MembershipEventWidget({
    super.key,
    required this.roomId,
    required this.eventItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //Return empty if membership content is not found
    MembershipContent? content = eventItem.membershipContent();
    if (content == null) return const SizedBox.shrink();

    //Get sender data
    final senderId = eventItem.sender();
    final senderNameProvider = ref.watch(
      memberDisplayNameProvider((roomId: roomId, userId: senderId)),
    );
    final senderName =
        senderNameProvider.valueOrNull ?? simplifyUserId(senderId) ?? senderId;

    //Get user data
    final userId = content.userId().toString();
    final userNameProvider = ref.watch(
      memberDisplayNameProvider((roomId: roomId, userId: userId)),
    );
    final userName =
        userNameProvider.valueOrNull ?? simplifyUserId(userId) ?? userId;

    //Design variables
    final theme = Theme.of(context);
    final isUnread = ref.watch(hasUnreadMessages(roomId)).valueOrNull ?? false;
    final color =
        isUnread ? theme.colorScheme.onSurface : theme.colorScheme.surfaceTint;
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: color,
      fontSize: 13,
    );

    //Get membership event text
    final membershipEventText = _getMembershipEventText(
      context: context,
      ref: ref,
      userName: userName,
      senderName: senderName,
      content: content,
    );

    //Return empty if text is null
    if (membershipEventText == null) return const SizedBox.shrink();

    //Render membership event text
    return Text(
      membershipEventText,
      maxLines: 2,
      style: textStyle,
      overflow: TextOverflow.ellipsis,
    );
  }

  String? _getMembershipEventText({
    required BuildContext context,
    required WidgetRef ref,
    required String userName,
    required String senderName,
    required MembershipContent content,
  }) {
    //Get language
    final lang = L10n.of(context);
    //Get my id
    final myId = ref.watch(myUserIdStrProvider);
    //Check if the action is mine
    final isMyAction = eventItem.sender().toString() == myId;
    //Check if the action is on me
    final isActionOnMe = content.userId().toString() == myId;

    return switch (content.change()) {
      //Member changes where 2 cases are possible
      'joined' =>
        isMyAction
            ? lang.chatMembershipYouJoined
            : lang.chatMembershipOtherJoined(userName),
      'left' =>
        isMyAction
            ? lang.chatMembershipYouLeft
            : lang.chatMembershipOtherLeft(userName),
      'invitationAccepted' =>
        isMyAction
            ? lang.chatMembershipInvitationYouAccepted
            : lang.chatMembershipInvitationOtherAccepted(userName),
      'invitationRejected' =>
        isMyAction
            ? lang.chatMembershipInvitationYouRejected
            : lang.chatMembershipInvitationOtherRejected(userName),
      'invitationRevoked' =>
        isMyAction
            ? lang.chatMembershipInvitationYouRevoked
            : lang.chatMembershipInvitationOtherRevoked(userName),
      'knockAccepted' =>
        isMyAction
            ? lang.chatMembershipKnockYouAccepted
            : lang.chatMembershipKnockOtherAccepted(userName),
      'knockRetracted' =>
        isMyAction
            ? lang.chatMembershipKnockYouRetracted
            : lang.chatMembershipKnockOtherRetracted(userName),
      'knockDenied' =>
        isMyAction
            ? lang.chatMembershipKnockYouDenied
            : lang.chatMembershipKnockOtherDenied(userName),

      //Member changes where 3 cases are possible
      'banned' =>
        isMyAction
            ? lang.chatMembershipYouBannedOther(userName)
            : isActionOnMe
            ? lang.chatMembershipOtherBannedYou(senderName)
            : lang.chatMembershipOtherBannedOther(senderName, userName),
      'unbanned' =>
        isMyAction
            ? lang.chatMembershipYouUnbannedOther(userName)
            : isActionOnMe
            ? lang.chatMembershipOtherUnbannedYou(senderName)
            : lang.chatMembershipOtherUnbannedOther(senderName, userName),
      'kicked' =>
        isMyAction
            ? lang.chatMembershipYouKickedOther(userName)
            : isActionOnMe
            ? lang.chatMembershipOtherKickedYou(senderName)
            : lang.chatMembershipOtherKickedOther(senderName, userName),
      'invited' =>
        isMyAction
            ? lang.chatMembershipYouInvitedOther(userName)
            : isActionOnMe
            ? lang.chatMembershipOtherInvitedYou(senderName)
            : lang.chatMembershipOtherInvitedOther(senderName, userName),
      'kickedAndBanned' =>
        isMyAction
            ? lang.chatMembershipYouKickedAndBannedOther(userName)
            : isActionOnMe
            ? lang.chatMembershipOtherKickedAndBannedYou(senderName)
            : lang.chatMembershipOtherKickedAndBannedOther(
              senderName,
              userName,
            ),
      'knocked' =>
        isMyAction
            ? lang.chatMembershipYouKnockedOther(userName)
            : isActionOnMe
            ? lang.chatMembershipOtherKnockedYou(senderName)
            : lang.chatMembershipOtherKnockedOther(senderName, userName),
      _ => null,
    };
  }
}
