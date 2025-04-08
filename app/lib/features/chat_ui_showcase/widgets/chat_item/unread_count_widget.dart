import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnreadCountWidget extends ConsumerWidget {
  final String roomId;

  const UnreadCountWidget({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //If unread count is not enabled, return a SizedBox.shrink()
    if (!ref.watch(isActiveProvider(LabsFeature.chatUnread))) {
      return SizedBox.shrink();
    }

    //Get the unread count for the room
    final unreadCount = ref.watch(unreadCountersProvider(roomId)).valueOrNull;
    if (unreadCount == null) return SizedBox.shrink();
    final (notifications, mentions, messages) = unreadCount;

    //If the unread count is 0, return a SizedBox.shrink()
    if (notifications == 0) return const SizedBox.shrink();

    //If the unread count is not 0, return a Container with the unread count
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        notifications.toString(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface,
          fontSize: 13,
        ),
      ),
    );
  }
}
