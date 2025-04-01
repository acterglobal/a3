import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/room_state.dart';
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
    final roomId = message.roomId.expect(
      'MembershipChange should have room id',
    );
    final eventType = message.metadata?['eventType'];
    final senderName =
        ref
            .watch(
              memberDisplayNameProvider((
                roomId: roomId,
                userId: message.author.id,
              )),
            )
            .valueOrNull ??
        simplifyUserId(message.author.id) ??
        message.author.id;
    if (eventType == 'membershipChange') {
      final userId = message.metadata?['userId'].expect(
        'MembershipChange should have user id',
      );
      final userName =
          ref
              .watch(
                memberDisplayNameProvider((roomId: roomId, userId: userId)),
              )
              .valueOrNull ??
          simplifyUserId(userId) ??
          userId;
      final change = message.metadata?['change'].expect(
        'MembershipChange should have change mode',
      );
      String? stateText = getStateOnMembershipChange(
        lang,
        change,
        myUserId,
        message.author.id,
        senderName,
        userId,
        userName,
      );
      if (stateText != null) {
        return Container(
          padding: const EdgeInsets.only(left: 10, bottom: 5),
          child: RichText(
            text: TextSpan(
              text: stateText,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        );
      }
    } else if (eventType == 'profileChange') {
      final metadata = message.metadata.expect(
        'ProfileChange should have metadata',
      );
      final userId = metadata['userId'].expect(
        'ProfileChange should have user id',
      );
      final userName =
          ref
              .watch(
                memberDisplayNameProvider((roomId: roomId, userId: userId)),
              )
              .valueOrNull ??
          simplifyUserId(userId) ??
          userId;
      String? stateText = getStateOnProfileChange(
        lang,
        metadata,
        myUserId,
        userId,
        userName,
      );
      if (stateText != null) {
        return Container(
          padding: const EdgeInsets.only(left: 10, bottom: 5),
          child: RichText(
            text: TextSpan(
              text: stateText,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }
}
