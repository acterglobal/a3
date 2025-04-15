import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/message_event_widget.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/text_message_widget.dart';
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

  bool _isUnread(WidgetRef ref) {
    if (!ref.watch(isActiveProvider(LabsFeature.chatUnread))) return false;
    return ref.watch(hasUnreadMessages(roomId)).valueOrNull ?? false;
  }

  String? _getLastMessageSenderNameText(TimelineEventItem? eventItem) {
    final sender = eventItem?.sender();
    if (sender == null) return null;
    final senderName = simplifyUserId(sender);
    if (senderName == null || senderName.isEmpty) return null;
    return senderName[0].toUpperCase() + senderName.substring(1);
  }

  String _getLastMessageText(L10n lang, TimelineEventItem? eventItem) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnread = _isUnread(ref);
    final isDM = ref.watch(isDirectChatProvider(roomId)).valueOrNull ?? false;
    final lastMessageProvider = ref.watch(latestMessageProvider(roomId));
    return lastMessageProvider.when(
      data:
          (timelineItem) =>
              _renderLastMessage(context, isUnread, isDM, timelineItem),
      error: (e, s) {
        _log.severe('Failed to load last message', e, s);
        return const SizedBox.shrink();
      },
      loading: () => Skeletonizer(child: Text('Loading...')),
    );
  }

  Widget _renderLastMessage(
    BuildContext context,
    bool isUnread,
    bool isDM,
    TimelineItem? timelineItem,
  ) {
    //Basical variables
    final theme = Theme.of(context);
    final lang = L10n.of(context);

    //Design variables
    final color =
        isUnread ? theme.colorScheme.onSurface : theme.colorScheme.surfaceTint;
    final bodySmallTextStyle = theme.textTheme.bodySmall?.copyWith(
      color: color,
      fontSize: 13,
    );

    //Data variables
    final senderName = _getLastMessageSenderNameText(timelineItem?.eventItem());
    final message = _getLastMessageText(lang, timelineItem?.eventItem());

    //Render last message
    switch (timelineItem?.eventItem()?.eventType()) {
      case 'm.room.encrypted':
        return TextMessageWidget(
          isDM: isDM,
          message: lang.failedToDecryptMessage,
          senderName: senderName,
          textStyle: bodySmallTextStyle,
        );
      case 'm.room.redaction':
        return TextMessageWidget(
          isDM: isDM,
          message: lang.thisMessageHasBeenDeleted,
          senderName: senderName,
          textStyle: bodySmallTextStyle,
        );
      case 'm.room.message':
        return MessageEventWidget(
          timelineItem: timelineItem,
          isDM: isDM,
          message: message,
          senderName: senderName,
          textStyle: bodySmallTextStyle,
        );
    }

    return TextMessageWidget(
      isDM: isDM,
      message: message,
      senderName: senderName,
      textStyle: bodySmallTextStyle,
    );
  }
}
