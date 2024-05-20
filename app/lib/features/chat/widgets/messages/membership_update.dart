import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MembershipUpdateWidget extends ConsumerWidget {
  final CustomMessage message;
  const MembershipUpdateWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUserId = ref.watch(myUserIdStrProvider);
    String? textMsg;
    final msgType = message.metadata?['msgType'];
    if (msgType == 'Joined') {
      if (message.author.id == myUserId) {
        textMsg = L10n.of(context).chatYouJoined;
      } else if (message.author.firstName != null) {
        textMsg =
            L10n.of(context).chatJoinedDisplayName(message.author.firstName!);
      } else {
        textMsg = L10n.of(context).chatJoinedUserId(message.author.id);
      }
    } else if (msgType == 'InvitationAccepted') {
      if (message.author.id == myUserId) {
        textMsg = L10n.of(context).chatYouAcceptedInvite;
      } else if (message.author.firstName != null) {
        textMsg = L10n.of(context)
            .chatInvitationAcceptedDisplayName(message.author.firstName!);
      } else {
        textMsg =
            L10n.of(context).chatInvitationAcceptedUserId(message.author.id);
      }
    } else if (msgType == 'Invited') {
      if (message.author.id == myUserId) {
        textMsg = L10n.of(context).chatYouInvited;
      } else if (message.author.firstName != null) {
        textMsg =
            L10n.of(context).chatInvitedDisplayName(message.author.firstName!);
      } else {
        textMsg = L10n.of(context).chatInvitedUserId(message.author.id);
      }
    } else {
      textMsg = message.metadata?['body'] ?? '';
    }
    return Container(
      padding: const EdgeInsets.only(left: 10, bottom: 5),
      child: RichText(
        text: TextSpan(
          text: textMsg,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.neutral5,
              ),
        ),
      ),
    );
  }
}
