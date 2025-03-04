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
    late String textMsg;
    final msgType = message.metadata?['msgType'];
    final firstName = message.author.firstName;
    if (msgType == 'Joined') {
      if (message.author.id == myUserId) {
        textMsg = lang.chatYouJoined;
      } else if (firstName != null) {
        textMsg = lang.chatJoinedDisplayName(firstName);
      } else {
        textMsg = lang.chatJoinedUserId(message.author.id);
      }
    } else if (msgType == 'InvitationAccepted') {
      if (message.author.id == myUserId) {
        textMsg = lang.chatYouAcceptedInvite;
      } else if (firstName != null) {
        textMsg = lang.chatInvitationAcceptedDisplayName(firstName);
      } else {
        textMsg = lang.chatInvitationAcceptedUserId(message.author.id);
      }
    } else if (msgType == 'Invited') {
      if (message.author.id == myUserId) {
        textMsg = lang.chatYouInvited('');
      } else if (firstName != null) {
        textMsg = lang.chatInvitedDisplayName(firstName, '');
      } else {
        textMsg = lang.chatInvitedUserId(message.author.id, '');
      }
    } else {
      textMsg = message.metadata?['body'] ?? '';
    }
    return Container(
      padding: const EdgeInsets.only(left: 10, bottom: 5),
      child: RichText(
        text: TextSpan(
          text: textMsg,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}
