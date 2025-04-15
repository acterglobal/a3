import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_list_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextMessageWidget extends ConsumerWidget {
  final String roomId;
  final TimelineEventItem eventItem;

  const TextMessageWidget({
    super.key,
    required this.roomId,
    required this.eventItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //Providers
    final isDM = ref.watch(isDirectChatProvider(roomId)).valueOrNull ?? false;
    final isUnread = ref.watch(hasUnreadMessages(roomId)).valueOrNull ?? false;
    final senderName = ref.watch(lastMessageSenderNameProvider(eventItem));
    final message = ref.watch(lastMessageTextProvider(eventItem));

    //Design variables
    final theme = Theme.of(context);
    final color =
        isUnread ? theme.colorScheme.onSurface : theme.colorScheme.surfaceTint;
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: color,
      fontSize: 13,
    );

    //Render
    final List<InlineSpan> spans = [];
    if (senderName != null && !isDM) {
      spans.add(TextSpan(text: '$senderName : ', style: textStyle));
    }
    spans.add(TextSpan(text: message ?? '', style: textStyle));

    return RichText(text: TextSpan(children: spans, style: textStyle));
  }
}
