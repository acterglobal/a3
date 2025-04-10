import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/room_member.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show MembershipChange, TimelineEventItem;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemberUpdateEvent extends ConsumerWidget {
  final bool isMe;
  final String roomId;
  final TimelineEventItem item;

  const MemberUpdateEvent({
    super.key,
    required this.isMe,
    required this.roomId,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String textMsg = getStateEventStr(context, ref, item) ?? '';

    return Container(
      padding: const EdgeInsets.only(left: 10, bottom: 5, right: 10),
      child: RichText(
        text: TextSpan(
          text: textMsg,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }

  String? getStateEventStr(
    BuildContext context,
    WidgetRef ref,
    TimelineEventItem item,
  ) {
    final lang = L10n.of(context);
    final myUserId = ref.read(myUserIdStrProvider);
    final senderId = item.sender();
    final senderName =
        ref
            .watch(
              memberDisplayNameProvider((roomId: roomId, userId: senderId)),
            )
            .valueOrNull ??
        simplifyUserId(senderId) ??
        senderId;
    MembershipChange content = item.membershipChange().expect(
      'failed to get content of membership change',
    );
    final userId = content.userId().toString();
    final userName =
        ref
            .watch(memberDisplayNameProvider((roomId: roomId, userId: userId)))
            .valueOrNull ??
        simplifyUserId(userId) ??
        userId;
    return getStateOnMembershipChange(
      lang,
      content.change(),
      myUserId,
      senderId,
      senderName,
      userId,
      userName,
    );
  }
}
