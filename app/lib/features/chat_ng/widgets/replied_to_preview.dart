import 'package:acter/common/toolkit/errors/inline_error_button.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/events/replied_to_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:acter/l10n/generated/l10n.dart';

// Reply State UI widget
class RepliedToPreview extends ConsumerWidget {
  final String roomId;
  final String messageId; // original message id of the
  final bool isMe;
  const RepliedToPreview({
    super.key,
    required this.roomId,
    required this.messageId,
    this.isMe = false,
  });

  RoomMsgId get replyInfo => (roomId: roomId, uniqueId: messageId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomMsgState = ref.watch(repliedToMsgProvider(replyInfo));

    return roomMsgState.when(
      loading:
          () => replyBuilder(
            context,
            Skeletonizer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Loading...'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: Text('Loading...'),
                  ),
                ],
              ),
            ),
          ),
      error:
          (error, stack) =>
              replyBuilder(context, replyErrorUI(context, ref, error, stack)),
      data:
          (repliedToItem) => replyBuilder(
            context,
            RepliedToEvent(
              roomId: roomId,
              originalMessageId: messageId,
              replyEventItem: repliedToItem,
            ),
          ),
    );
  }

  Widget replyErrorUI(
    BuildContext context,
    WidgetRef ref,
    Object error,
    StackTrace? stack,
  ) {
    return ActerInlineErrorButton(
      error: error,
      stack: stack,
      child: Text(
        L10n.of(context).repliedToMsgFailed(error.toString()),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      onRetryTap: () => ref.invalidate(repliedToMsgProvider(replyInfo)),
    );
  }

  Widget replyBuilder(BuildContext context, Widget child) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color:
            isMe
                ? colorScheme.surface.withValues(alpha: 0.3)
                : colorScheme.onSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }
}
