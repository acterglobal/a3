import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class MembershipUpdateWidget extends StatelessWidget {
  final CustomMessage message;
  const MembershipUpdateWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final textMsg = switch (message.metadata?['msgType']) {
      'Joined' => message.author.firstName != null
          ? L10n.of(context).chatJoinedDisplayName(message.author.firstName!)
          : L10n.of(context).chatJoinedUserId(message.author.id),
      'InvitationAccepted' => message.author.firstName != null
          ? L10n.of(context)
              .chatInvitationAcceptedDisplayName(message.author.firstName!)
          : L10n.of(context).chatInvitationAcceptedUserId(message.author.id),
      'Invited' => message.author.firstName != null
          ? L10n.of(context).chatInvitedDisplayName(message.author.firstName!)
          : L10n.of(context).chatInvitedUserId(message.author.id),
      _ => message.metadata?['body'] ?? '',
    };
    return Container(
      padding: const EdgeInsets.only(left: 10, bottom: 5),
      child: RichText(
        text: TextSpan(
          text: textMsg,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}
