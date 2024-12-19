import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat/widgets/messages/encrypted_message.dart';
import 'package:acter/features/chat/widgets/messages/redacted_message.dart';
import 'package:acter/features/chat_ng/widgets/events/file_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/image_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/text_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/video_message_event.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomEventItem, RoomMessage;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:acter/common/extensions/options.dart';

class ReplyOriginalEvent extends StatelessWidget {
  final String roomId;
  final RoomMessage msg;
  const ReplyOriginalEvent({
    super.key,
    required this.roomId,
    required this.msg,
  });

  @override
  Widget build(BuildContext context) {
    // reply is allowed for only EventItem not VirtualItem
    // user should be able to get original event as RoomMessage
    RoomEventItem replyEventItem =
        msg.eventItem().expect('room msg should have event item');
    final messageId = msg.uniqueId();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer(
          builder: (context, ref, child) => replyProfileBuilder(
            context,
            ref,
            roomId,
            replyEventItem,
          ),
        ),
        // const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: OriginalEventItem(
            roomId: roomId,
            messageId: messageId,
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
    RoomEventItem item,
  ) {
    final replyProfile = ref.watch(
      memberAvatarInfoProvider((userId: item.sender(), roomId: roomId)),
    );

    return Row(
      children: [
        ActerAvatar(
          options: AvatarOptions.DM(
            replyProfile,
            size: 12,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          replyProfile.displayName ?? '',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.tertiary),
        ),
      ],
    );
  }
}

class OriginalEventItem extends ConsumerWidget {
  final String roomId;
  final String messageId;
  final RoomEventItem item;
  const OriginalEventItem({
    super.key,
    required this.roomId,
    required this.messageId,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(myUserIdStrProvider);
    final isUser = myId == item.sender();
    final eventType = item.eventType();
    return switch (eventType) {
      // handle message inner types separately
      'm.room.message' => buildReplyMsgEventItem(
          roomId,
          messageId,
          item,
          isUser,
        ),
      'm.room.redaction' => RedactedMessageWidget(),
      'm.room.encrypted' => EncryptedMessageWidget(),
      _ => _buildUnsupportedMessage(eventType),
    };
  }

  Widget buildReplyMsgEventItem(
    String roomId,
    String messageId,
    RoomEventItem item,
    bool isUser,
  ) {
    final msgType = item.msgType();
    final content = item.msgContent();

    // shouldn't happen but in case return empty
    if (msgType == null || content == null) return const SizedBox.shrink();

    return switch (msgType) {
      'm.emote' || 'm.text' => TextMessageEvent.reply(
          roomId: roomId,
          content: content,
        ),
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
    return Text(
      'Unsupported event type: $msgtype',
    );
  }
}
