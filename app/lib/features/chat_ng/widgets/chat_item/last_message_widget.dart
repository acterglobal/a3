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
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
        return _renderTextMessageUI(
          isDM: isDM,
          message: lang.failedToDecryptMessage,
          senderName: senderName,
          textStyle: bodySmallTextStyle,
        );
      case 'm.room.redaction':
        return _renderTextMessageUI(
          isDM: isDM,
          message: lang.thisMessageHasBeenDeleted,
          senderName: senderName,
          textStyle: bodySmallTextStyle,
        );
      case 'm.room.message':
        switch (timelineItem?.eventItem()?.msgType()) {
          case 'm.text':
            return _renderTextMessageUI(
              isDM: isDM,
              message: message,
              senderName: senderName,
              textStyle: bodySmallTextStyle,
            );
          case 'm.image':
            return _renderIconMessageUI(
              isDM: isDM,
              icon: PhosphorIcons.image(),
              message: lang.image,
              senderName: senderName,
              textStyle: bodySmallTextStyle,
            );
          case 'm.video':
            return _renderIconMessageUI(
              isDM: isDM,
              icon: PhosphorIcons.video(),
              message: lang.video,
              senderName: senderName,
              textStyle: bodySmallTextStyle,
            );
          case 'm.audio':
            return _renderIconMessageUI(
              isDM: isDM,
              icon: PhosphorIcons.musicNote(),
              message: lang.audio,
              senderName: senderName,
              textStyle: bodySmallTextStyle,
            );
          case 'm.file':
            return _renderIconMessageUI(
              isDM: isDM,
              icon: PhosphorIcons.file(),
              message: lang.file,
              senderName: senderName,
              textStyle: bodySmallTextStyle,
            );
          case 'm.location':
            return _renderIconMessageUI(
              isDM: isDM,
              icon: PhosphorIcons.mapPin(),
              message: lang.location,
              senderName: senderName,
              textStyle: bodySmallTextStyle,
            );
        }
    }

    return _renderTextMessageUI(
      isDM: isDM,
      message: message,
      senderName: senderName,
      textStyle: bodySmallTextStyle,
    );
  }

  Widget _renderTextMessageUI({
    required bool isDM,
    required String message,
    String? senderName,
    TextStyle? textStyle,
  }) {
    return RichText(
      text: TextSpan(
        children: [
          if (senderName != null && !isDM)
            TextSpan(text: '$senderName : ', style: textStyle),
          TextSpan(text: message, style: textStyle),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _renderIconMessageUI({
    required bool isDM,
    required IconData icon,
    required String message,
    String? senderName,
    TextStyle? textStyle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (senderName != null && !isDM)
          Text('$senderName : ', style: textStyle),
        Icon(icon, size: 14, color: textStyle?.color),
        const SizedBox(width: 4),
        Text(message, style: textStyle),
      ],
    );
  }
}
