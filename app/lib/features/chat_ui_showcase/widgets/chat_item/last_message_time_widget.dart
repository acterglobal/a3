import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LastMessageTimeWidget extends ConsumerWidget {
  final String roomId;
  final bool? mockIsUnread;
  final int? mockLastMessageTimestamp;

  const LastMessageTimeWidget({
    super.key,
    required this.roomId,
    this.mockIsUnread,
    this.mockLastMessageTimestamp,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final isUnread = mockIsUnread ?? _isUnread(ref);

    final timeColor =
        isUnread ? theme.colorScheme.onSurface : theme.colorScheme.surfaceTint;

    final lastMessageTimestamp =
        mockLastMessageTimestamp ?? _getLastMessageTimestamp(ref);

    if (lastMessageTimestamp == null) return const SizedBox.shrink();

    return Text(
      jiffyTime(context, lastMessageTimestamp),
      style: theme.textTheme.bodySmall?.copyWith(
        color: timeColor,
        fontSize: 12,
      ),
    );
  }

  bool _isUnread(WidgetRef ref) {
    if (!ref.watch(isActiveProvider(LabsFeature.chatUnread))) return false;
    return ref.watch(hasUnreadMessages(roomId)).valueOrNull ?? false;
  }

  int? _getLastMessageTimestamp(WidgetRef ref) {
    final latestMessage = ref.watch(latestMessageProvider(roomId)).valueOrNull;
    final TimelineEventItem? eventItem = latestMessage?.eventItem();
    final lastMessageTimestamp = eventItem?.originServerTs();
    return lastMessageTimestamp;
  }
}
