import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::chat-item::last-message-widget');

class LastMessageWidget extends ConsumerWidget {
  final String roomId;

  const LastMessageWidget({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastMessageProvider = ref.watch(latestMessageProvider(roomId));

    return lastMessageProvider.when(
      data: (timelineItem) => _renderLastMessage(context, ref, timelineItem),
      error: (e, s) {
        _log.severe('Failed to load last message', e, s);
        return const SizedBox.shrink();
      },
      loading: () => Skeletonizer(child: Text('Loading...')),
    );
  }

  Widget _renderLastMessage(
    BuildContext context,
    WidgetRef ref,
    TimelineItem? timelineItem,
  ) {
    final lang = L10n.of(context);
    final theme = Theme.of(context);
    final isDM = _getIsDM(ref);
    final isUnread = _isUnread(ref);
    final textColor =
        isUnread ? theme.colorScheme.onSurface : theme.colorScheme.surfaceTint;

    final senderName = _getLastMessageSenderName(timelineItem?.eventItem());
    final message = _getLastMessage(lang, timelineItem?.eventItem());

    return RichText(
      text: TextSpan(
        children: [
          if (senderName != null && !isDM)
            TextSpan(
              text: '$senderName : ',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: textColor,
                fontSize: 14,
              ),
            ),
          TextSpan(
            text: message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  bool _getIsDM(WidgetRef ref) {
    final isDM = ref.watch(isDirectChatProvider(roomId));
    return isDM.valueOrNull ?? false;
  }

  bool _isUnread(WidgetRef ref) {
    if (!ref.watch(isActiveProvider(LabsFeature.chatUnread))) return false;
    return ref.watch(hasUnreadMessages(roomId)).valueOrNull ?? false;
  }

  String? _getLastMessageSenderName(TimelineEventItem? eventItem) {
    final sender = eventItem?.sender();
    if (sender == null) return null;
    final senderName = simplifyUserId(sender);
    if (senderName == null || senderName.isEmpty) return null;
    return senderName[0].toUpperCase() + senderName.substring(1);
  }

  String _getLastMessage(L10n lang, TimelineEventItem? eventItem) {
    switch (eventItem?.eventType()) {
      case 'm.room.encrypted':
        return lang.failedToDecryptMessage;
      case 'm.room.redaction':
        return lang.thisMessageHasBeenDeleted;
      default:
        final msgContent = eventItem?.msgContent();
        return msgContent?.body() ?? '';
    }
  }
}
