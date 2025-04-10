import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/room_member.dart';
import 'package:acter/common/utils/utils.dart';
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
    String roomId = message.roomId.expect(
      'failed to get room id of membership change',
    );
    String change = message.metadata?['change'];
    String senderId = message.author.id;
    final senderName =
        ref
            .watch(
              memberDisplayNameProvider((roomId: roomId, userId: senderId)),
            )
            .valueOrNull ??
        simplifyUserId(senderId) ??
        senderId;
    String userId = message.metadata?['userId'];
    final userName =
        ref
            .watch(memberDisplayNameProvider((roomId: roomId, userId: userId)))
            .valueOrNull ??
        simplifyUserId(userId) ??
        userId;
    String? body = getStateOnMembershipChange(
      lang,
      change,
      myUserId,
      senderId,
      senderName,
      userId,
      userName,
    );
    return Container(
      padding: const EdgeInsets.only(left: 10, bottom: 5),
      child: RichText(
        text: TextSpan(
          text: body ?? '',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}
