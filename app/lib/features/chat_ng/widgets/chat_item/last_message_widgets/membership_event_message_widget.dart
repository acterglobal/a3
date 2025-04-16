import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_list_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MembershipEventMessageWidget extends ConsumerWidget {
  final String roomId;
  final TimelineEventItem eventItem;

  const MembershipEventMessageWidget({
    super.key,
    required this.roomId,
    required this.eventItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);

    //Providers
    final isUnread = ref.watch(hasUnreadMessages(roomId)).valueOrNull ?? false;
    final senderName = ref.watch(lastMessageSenderNameProvider(eventItem));
    final senderId = eventItem.sender();
    final myUserId = ref.watch(myUserIdStrProvider);
    final isMe = senderId == myUserId;

    //Design variables
    final theme = Theme.of(context);
    final color =
        isUnread ? theme.colorScheme.onSurface : theme.colorScheme.surfaceTint;
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: color,
      fontSize: 13,
    );

    //Get the text for the membership event
    final String membershipText = switch (eventItem.msgType()) {
      'Joined' =>
        (isMe)
            ? lang.chatMembershipYouJoined
            : lang.chatMembershipOtherJoined(senderName ?? senderId),
      'InvitationAccepted' =>
        (isMe)
            ? lang.chatMembershipInvitationYouAccepted
            : lang.chatMembershipInvitationOtherAccepted(
              senderName ?? senderId,
            ),
      'Invited' =>
        (isMe)
            ? lang.chatMembershipYouInvitedOther(senderName ?? senderId)
            : lang.chatMembershipOtherInvitedOther(senderName ?? senderId, ''),
      'kicked' =>
        (isMe)
            ? lang.chatMembershipYouKickedAndBannedOther(senderName ?? senderId)
            : lang.chatMembershipOtherKickedAndBannedOther(
              senderName ?? senderId,
              '',
            ),
      'banned' =>
        (isMe)
            ? lang.chatMembershipYouKickedAndBannedOther(senderName ?? senderId)
            : lang.chatMembershipOtherKickedAndBannedOther(
              senderName ?? senderId,
              '',
            ),
      'left' =>
        (isMe)
            ? lang.chatMembershipYouLeft
            : lang.chatMembershipOtherLeft(senderName ?? senderId),
      'invitationRevoked' =>
        (isMe)
            ? lang.chatMembershipInvitationYouRevoked
            : lang.chatMembershipInvitationOtherRevoked(senderName ?? senderId),
      _ => '',
    };

    //Render the text
    return Text(membershipText, style: textStyle);
  }
}
