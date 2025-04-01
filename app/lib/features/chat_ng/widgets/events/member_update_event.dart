import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/room_state.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem;
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
    String textMsg = getStateEventStr(context, ref, item);

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

  String getStateEventStr(
    BuildContext context,
    WidgetRef ref,
    TimelineEventItem item,
  ) {
    final lang = L10n.of(context);
    final myId = ref.watch(myUserIdStrProvider);

    final eventType = item.eventType();
    final senderId = item.sender();
    final senderName =
        ref
            .watch(
              memberDisplayNameProvider((roomId: roomId, userId: senderId)),
            )
            .valueOrNull ??
        senderId;

    if (eventType == 'membershipChange') {
      final content = item.membershipChange().expect(
        'failed to get content of membership change',
      );
      final change = content.change().expect(
        'MembershipChange should have change mode',
      );
      final userId = content.userId().toString();
      final userName =
          ref
              .watch(
                memberDisplayNameProvider((roomId: roomId, userId: userId)),
              )
              .valueOrNull ??
          simplifyUserId(userId) ??
          userId;
      final stateText = getStateOnMembershipChange(
        lang,
        change,
        myId,
        senderId,
        senderName,
        userId,
        userName,
      );
      if (stateText != null) return stateText;
    } else if (eventType == 'profileChange') {
      final content = item.profileChange().expect(
        'failed to get content of profile change',
      );
      final userId = content.userId().toString();
      final userName =
          ref
              .watch(
                memberDisplayNameProvider((roomId: roomId, userId: userId)),
              )
              .valueOrNull ??
          simplifyUserId(userId) ??
          userId;
      Map<String, dynamic> metadata = {};
      switch (content.displayNameChange()) {
        case 'Changed':
          metadata['displayName'] = {
            'change': 'Changed',
            'oldVal': content.displayNameOldVal(),
            'newVal': content.displayNameNewVal(),
          };
          break;
        case 'Unset':
          metadata['displayName'] = {
            'change': 'Unset',
            'oldVal': content.displayNameOldVal(),
          };
          break;
        case 'Set':
          metadata['displayName'] = {
            'change': 'Set',
            'newVal': content.displayNameNewVal(),
          };
          break;
      }
      switch (content.avatarUrlChange()) {
        case 'Changed':
          metadata['avatarUrl'] = {
            'change': 'Changed',
            'oldVal': content.avatarUrlOldVal().toString(),
            'newVal': content.avatarUrlNewVal().toString(),
          };
          break;
        case 'Unset':
          metadata['avatarUrl'] = {
            'change': 'Unset',
            'oldVal': content.avatarUrlOldVal().toString(),
          };
          break;
        case 'Set':
          metadata['avatarUrl'] = {
            'change': 'Set',
            'newVal': content.avatarUrlNewVal().toString(),
          };
          break;
      }
      final stateText = getStateOnProfileChange(
        lang,
        metadata,
        myId,
        userId,
        userName,
      );
      if (stateText != null) return stateText;
    }
    return '';
  }
}
