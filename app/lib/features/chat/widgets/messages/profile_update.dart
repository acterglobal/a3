import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/room_member.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileUpdateWidget extends ConsumerWidget {
  final CustomMessage message;

  const ProfileUpdateWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final myUserId = ref.watch(myUserIdStrProvider);
    String roomId = message.roomId.expect(
      'room id should be specified in custom message for profile change',
    );
    final metadata = message.metadata.expect(
      'metadata should be specified in custom message for profile change',
    );
    String userId = metadata['userId'];
    final userName =
        ref
            .watch(memberDisplayNameProvider((roomId: roomId, userId: userId)))
            .valueOrNull ??
        simplifyUserId(userId) ??
        userId;
    String? body = getStateOnProfileChange(
      lang,
      metadata,
      myUserId,
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
