import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MembershipUpdateWidget extends ConsumerWidget {
  final CustomMessage message;

  const MembershipUpdateWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final myUserId = ref.watch(myUserIdStrProvider);
    late String senderId; // he changed another user
    if (message.author.id == myUserId) {
      senderId = lang.you;
    } else {
      senderId =
          ref
              .watch(
                memberDisplayNameProvider((
                  roomId: message.roomId ?? '',
                  userId: message.author.id,
                )),
              )
              .valueOrNull ??
          message.author.id;
    }
    late String userId; // he was changed by sender
    if (message.metadata?['userId'] == myUserId) {
      userId = lang.you;
    } else {
      userId =
          ref
              .watch(
                memberDisplayNameProvider((
                  roomId: message.roomId ?? '',
                  userId: message.metadata?['userId'],
                )),
              )
              .valueOrNull ??
          message.metadata?['userId'];
    }
    late String text;
    switch (message.metadata?['change']) {
      case 'None':
        text = lang.chatMembershipNone(userId);
        break;
      case 'Error':
        text = lang.chatMembershipError(userId);
        break;
      case 'Joined':
        text = lang.chatMembershipJoined(userId);
        break;
      case 'Left':
        text = lang.chatMembershipLeft(userId);
        break;
      case 'Banned':
        text = lang.chatMembershipBanned(senderId, userId);
        break;
      case 'Unbanned':
        text = lang.chatMembershipUnbanned(senderId, userId);
        break;
      case 'Kicked':
        text = lang.chatMembershipKicked(senderId, userId);
        break;
      case 'Invited':
        text = lang.chatMembershipInvited(senderId, userId);
        break;
      case 'KickedAndBanned':
        text = lang.chatMembershipKickedAndBanned(senderId, userId);
        break;
      case 'InvitationAccepted':
        text = lang.chatMembershipInvitationAccepted(userId);
        break;
      case 'InvitationRejected':
        text = lang.chatMembershipInvitationRejected(userId);
        break;
      case 'InvitationRevoked':
        text = lang.chatMembershipInvitationRevoked(userId);
        break;
      case 'Knocked':
        text = lang.chatMembershipKnocked(senderId, userId);
        break;
      case 'KnockAccepted':
        text = lang.chatMembershipKnockAccepted(userId);
        break;
      case 'KnockRetracted':
        text = lang.chatMembershipKnockRetracted(userId);
        break;
      case 'KnockDenied':
        text = lang.chatMembershipKnockDenied(userId);
        break;
      case 'NotImplemented':
        text = lang.chatMembershipNotImplemented(userId);
        break;
      default:
        text = lang.chatMembershipNone(userId);
        break;
    }
    return Container(
      padding: const EdgeInsets.only(left: 10, bottom: 5),
      child: RichText(
        text: TextSpan(
          text: text,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}
