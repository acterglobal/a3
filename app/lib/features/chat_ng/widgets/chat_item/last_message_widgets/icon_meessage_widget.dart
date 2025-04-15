import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_list_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IconMessageWidget extends ConsumerWidget {
  final String roomId;
  final TimelineEventItem eventItem;
  final IconData icon;

  const IconMessageWidget({
    super.key,
    required this.roomId,
    required this.eventItem,
    required this.icon,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (senderName != null && !isDM)
          Text('$senderName : ', style: textStyle),
        Icon(icon, size: 14, color: textStyle?.color),
        const SizedBox(width: 4),
        Text(message ?? '', style: textStyle),
      ],
    );
  }
}
