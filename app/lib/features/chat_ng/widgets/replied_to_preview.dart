import 'package:acter/features/chat_ng/models/replied_to_msg_state.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/events/replied_to_event.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

// Reply State UI widget
class RepliedToPreview extends ConsumerWidget {
  final String roomId;
  final String originalId;
  final bool isMe;
  const RepliedToPreview({
    super.key,
    required this.roomId,
    required this.originalId,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RoomMsgId replyInfo = (roomId: roomId, uniqueId: originalId);

    final roomMsgState = ref.watch(repliedToMsgProvider(replyInfo)).valueOrNull;

    return switch (roomMsgState) {
      RepliedToMsgLoading() => replyBuilder(
          context,
          Skeletonizer(
            child: ListTile(
              leading: ActerAvatar(
                options: AvatarOptions.DM(AvatarInfo(uniqueId: '#')),
              ),
              isThreeLine: true,
            ),
          ),
        ),
      RepliedToMsgError() => replyBuilder(
          context,
          replyErrorUI(context, ref, replyInfo),
        ),
      RepliedToMsgData(repliedToItem: final repliedToItem) => replyBuilder(
          context,
          RepliedToEvent(
            roomId: roomId,
            messageId: originalId,
            replyEventItem: repliedToItem,
          ),
        ),
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
      L10n.of(context).repliedToMsgFailed(originalId),
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
        color: isMe
            ? colorScheme.surface.withValues(alpha:0.3)
            : colorScheme.onSurface.withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }
}
