import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnreadCountWidget extends ConsumerWidget {
  final String roomId;
  final bool inverse;

  const UnreadCountWidget({
    super.key,
    required this.roomId,
    this.inverse = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = _getUnreadCount(ref);

    //If the unread count is not 0, return a Container with the unread count
    if (unreadCount == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            inverse ? theme.colorScheme.onSurface : theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        unreadCount.toString(),
        style: theme.textTheme.bodySmall?.copyWith(
          color:
              inverse ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  int _getUnreadCount(WidgetRef ref) {
    //If unread count is not enabled, return a SizedBox.shrink()
    if (!ref.watch(isActiveProvider(LabsFeature.chatUnread))) {
      return 0;
    }

    //Get the unread count for the room
    final unreadCountData =
        ref.watch(unreadCountersProvider(roomId)).valueOrNull;
    if (unreadCountData == null) return 0;
    final (notifications, mentions, messages) = unreadCountData;

    return notifications;
  }
}
