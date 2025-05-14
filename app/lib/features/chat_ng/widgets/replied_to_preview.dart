import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/errors/inline_error_button.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/utils.dart';
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
    final theme = Theme.of(context);
    final roomMsgState = ref.watch(repliedToMsgProvider(replyInfo));

    return roomMsgState.when(
      loading:
          () => replyBuilderContainerUI(
            context: context,
            child: Skeletonizer(
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
            displayNameColor: theme.colorScheme.onPrimary,
          ),
      error: (error, stack) => replyErrorUI(context, ref, error, stack),
      data: (repliedToItem) {
        final replyProfile = ref.watch(
          memberAvatarInfoProvider((
            userId: repliedToItem.sender(),
            roomId: roomId,
          )),
        );
        final String displayName =
            replyProfile.displayName ?? replyProfile.uniqueName ?? '';

        return replyBuilderContainerUI(
          context: context,
          child: RepliedToEvent(
            roomId: roomId,
            originalMessageId: messageId,
            replyEventItem: repliedToItem,
          ),
          displayNameColor:
              chatBubbleDisplayNameColors[displayName.hashCode.abs() %
                  chatBubbleDisplayNameColors.length],
        );
      },
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

  Widget replyBuilderContainerUI({
    required BuildContext context,
    required Widget child,
    required Color displayNameColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isMe ? Colors.black26 : Colors.white10,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: displayNameColor,
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
