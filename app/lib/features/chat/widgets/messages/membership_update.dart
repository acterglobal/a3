import 'package:acter/common/providers/common_providers.dart';
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
    late String userId;
    if (message.author.id == myUserId) {
      userId = lang.you;
    } else {
      userId = message.author.firstName ?? message.author.id;
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
        text = lang.chatMembershipBanned(userId);
        break;
      case 'Unbanned':
        text = lang.chatMembershipUnbanned(userId);
        break;
      case 'Kicked':
        text = lang.chatMembershipKicked(userId);
        break;
      case 'Invited':
        text = lang.chatMembershipInvited(userId);
        break;
      case 'KickedAndBanned':
        text = lang.chatMembershipKickedAndBanned(userId);
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
        text = lang.chatMembershipKnocked(userId);
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
