import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat/widgets/messages/encrypted_message.dart';
import 'package:acter/features/chat/widgets/messages/redacted_message.dart';
import 'package:acter/features/chat_ng/utils.dart';
import 'package:acter/features/chat_ng/widgets/events/file_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/image_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/text_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/video_message_event.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RepliedToEvent extends StatelessWidget {
  final String roomId;
  final String originalMessageId;
  final TimelineEventItem replyEventItem;
  const RepliedToEvent({
    super.key,
    required this.roomId,
    required this.originalMessageId,
    required this.replyEventItem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer(
          builder:
              (context, ref, child) =>
                  replyProfileBuilder(context, ref, roomId, replyEventItem),
        ),
        // const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 4),
          child: _OriginalEventItem(
            roomId: roomId,
            originalMessageId: originalMessageId,
            item: replyEventItem,
          ),
        ),
      ],
    );
  }

  Widget replyProfileBuilder(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    TimelineEventItem item,
  ) {
    final replyProfile = ref.watch(
      memberAvatarInfoProvider((userId: item.sender(), roomId: roomId)),
    );
    final String displayName = replyProfile.displayName ?? item.sender();

    return Row(
      children: [
        ActerAvatar(options: AvatarOptions.DM(replyProfile, size: 12)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            displayName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color:
                  chatBubbleDisplayNameColors[displayName.hashCode.abs() %
                      chatBubbleDisplayNameColors.length],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _OriginalEventItem extends ConsumerWidget {
  final String roomId;
  final String originalMessageId;
  final TimelineEventItem item;
  const _OriginalEventItem({
    required this.roomId,
    required this.originalMessageId,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(myUserIdStrProvider);
    final isUser = myId == item.sender();
    final eventType = item.eventType();
    return switch (eventType) {
      // handle message inner types separately
      'm.room.message' => buildReplyMsgEventItem(context, roomId, item, isUser),
      'm.room.redaction' => RedactedMessageWidget(),
      'm.room.encrypted' => EncryptedMessageWidget(),
      _ => _buildUnsupportedMessage(eventType),
    };
  }

  Widget buildReplyMsgEventItem(
    BuildContext context,
    String roomId,
    TimelineEventItem item,
    bool isUser,
  ) {
    final msgType = item.msgType();
    final content = item.msgContent();
    final messageId = item.eventId();

    // shouldn't happen but in case return empty
    if (msgType == null || content == null) return const SizedBox.shrink();

    if (messageId == null) {
      return Text(L10n.of(context).repliedToMsgFailed('missing event id'));
    }

    return switch (msgType) {
      'm.emote' ||
      'm.text' => TextMessageEvent.reply(roomId: roomId, content: content),
      'm.image' => ImageMessageEvent(
        messageId: messageId,
        roomId: roomId,
        content: content,
      ),
      'm.video' => VideoMessageEvent(
        roomId: roomId,
        messageId: messageId,
        content: content,
      ),
      'm.file' => FileMessageEvent(
        roomId: roomId,
        messageId: messageId,
        content: content,
      ),
      _ => _buildUnsupportedMessage(msgType),
    };
  }

  Widget _buildUnsupportedMessage(String? msgtype) {
    return Text('Unsupported event type: $msgtype');
  }
}
