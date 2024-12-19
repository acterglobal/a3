import 'package:acter/features/chat_ng/models/reply_message_state.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/events/reply_original_event.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

// Reply State UI widget
class RepliedToPreview extends ConsumerWidget {
  final String roomId;
  final String originalId;
  final bool isUser;
  const RepliedToPreview({
    super.key,
    required this.roomId,
    required this.originalId,
    this.isUser = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RoomMsgId replyInfo = (roomId: roomId, uniqueId: originalId);

    final roomMsgState = ref.watch(replyToMsgProvider(replyInfo)).valueOrNull;
    final avatarInfo = AvatarInfo(uniqueId: '#');

    return switch (roomMsgState) {
      ReplyMsgLoading() => replyBuilder(
          context,
          Skeletonizer(
            child: ListTile(
              leading: ActerAvatar(options: AvatarOptions.DM(avatarInfo)),
              isThreeLine: true,
            ),
          ),
        ),
      ReplyMsgError() => replyBuilder(
          context,
          replyErrorUI(context, ref, replyInfo),
        ),
      ReplyMsgData(message: final msg) =>
        replyBuilder(context, ReplyOriginalEvent(roomId: roomId, msg: msg)),
      _ => const SizedBox.shrink(),
    };
  }

  Widget replyErrorUI(
    BuildContext context,
    WidgetRef ref,
    RoomMsgId replyInfo,
  ) {
    final originalId = replyInfo.uniqueId;
    return Text(
      'Failed to load original message id: $originalId',
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.error),
    );
  }

  Widget replyBuilder(BuildContext context, Widget child) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: isUser
            ? colorScheme.surface.withOpacity(0.3)
            : colorScheme.onSurface.withOpacity(0.2),
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }
}
