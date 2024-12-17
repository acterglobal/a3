import 'package:acter/features/chat_ng/models/message_metadata.dart';
import 'package:acter/features/chat_ng/models/reply_message_state.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/events/reply_original_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/extensions/options.dart';

// Reply State UI widget
class ReplyPreview extends ConsumerWidget {
  final MessageMetadata metadata;
  const ReplyPreview({
    super.key,
    required this.metadata,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String roomId = metadata.roomId;
    final String messageId = metadata.messageId;
    final String originalId =
        metadata.repliedTo.expect('should always contain replied id');
    final ReplyMsgInfo replyInfo =
        (roomId: roomId, messageId: messageId, originalId: originalId);

    final roomMsgState = ref.watch(replyToMsgProvider(replyInfo)).valueOrNull;

    return switch (roomMsgState) {
      ReplyMsgLoading() => replyBuilder(
          context,
          Center(child: CircularProgressIndicator()),
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
    ReplyMsgInfo replyInfo,
  ) {
    final originalId = replyInfo.originalId;
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
    final bool isUser = metadata.isUser;
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
