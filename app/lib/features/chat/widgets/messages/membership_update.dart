import 'package:acter/common/providers/common_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MembershipUpdateWidget extends ConsumerWidget {
  final CustomMessage message;

  const MembershipUpdateWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUserId = ref.watch(myUserIdStrProvider);
    final firstName = message.author.firstName;
    String textMsg = switch (message.metadata?['msgType']) {
      'Joined' => message.author.id == myUserId
          ? L10n.of(context).chatYouJoined
          : firstName != null
              ? L10n.of(context).chatJoinedDisplayName(firstName)
              : L10n.of(context).chatJoinedUserId(message.author.id),
      'InvitationAccepted' => message.author.id == myUserId
          ? L10n.of(context).chatYouAcceptedInvite
          : firstName != null
              ? L10n.of(context).chatInvitationAcceptedDisplayName(firstName)
              : L10n.of(context)
                  .chatInvitationAcceptedUserId(message.author.id),
      'Invited' => message.author.id == myUserId
          ? L10n.of(context).chatYouInvited
          : firstName != null
              ? L10n.of(context).chatInvitedDisplayName(firstName)
              : L10n.of(context).chatInvitedUserId(message.author.id),
      _ => message.metadata?['body'] ?? '',
    };
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
