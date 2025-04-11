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
        textMsg = lang.chatMembershipYouJoined;
      } else if (firstName != null) {
        textMsg = lang.chatMembershipOtherJoined(firstName);
      } else {
        textMsg = lang.chatMembershipOtherJoined(message.author.id);
      }
    } else if (msgType == 'InvitationAccepted') {
      if (message.author.id == myUserId) {
        textMsg = lang.chatMembershipInvitationYouAccepted;
      } else if (firstName != null) {
        textMsg = lang.chatMembershipInvitationOtherAccepted(firstName);
      } else {
        textMsg = lang.chatMembershipInvitationOtherAccepted(message.author.id);
      }
    } else if (msgType == 'Invited') {
      if (message.author.id == myUserId) {
        textMsg = lang.chatMembershipYouInvitedOther('');
      } else if (firstName != null) {
        textMsg = lang.chatMembershipOtherInvitedOther(firstName, '');
      } else {
        textMsg = lang.chatMembershipOtherInvitedOther(message.author.id, '');
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
