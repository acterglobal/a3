import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/datetime/providers/utc_now_provider.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::chat-item::last-message-time-widget');

class LastMessageTimeWidget extends ConsumerWidget {
  final String roomId;

  const LastMessageTimeWidget({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastMessageProvider = ref.watch(latestMessageProvider(roomId));

    return lastMessageProvider.when(
      data:
          (timelineItem) => _renderLastMessageTime(context, ref, timelineItem),
      error: (e, s) {
        _log.severe('Failed to load last message time', e, s);
        return const SizedBox.shrink();
      },
      loading: () => Skeletonizer(child: Text('Today')),
    );
  }

  Widget _renderLastMessageTime(
    BuildContext context,
    WidgetRef ref,
    TimelineItem? timelineItem,
  ) {
    final theme = Theme.of(context);
    final isUnread = _isUnread(ref);
    final timeColor =
        isUnread ? theme.colorScheme.onSurface : theme.colorScheme.surfaceTint;

    final eventItem = timelineItem?.eventItem();
    if (eventItem == null) return const SizedBox.shrink();

    return Text(
      jiffyTime(
        context,
        eventItem.originServerTs(),
        toWhen: ref.watch(utcNowProvider),
      ),
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
}
