import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat/widgets/messages/encrypted_message.dart';
import 'package:acter/features/chat/widgets/messages/redacted_message.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/chat_bubble.dart';
import 'package:acter/features/chat_ng/widgets/events/file_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/image_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/text_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/video_message_event.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::widgets::room_message');

class ChatEvent extends ConsumerWidget {
  final String roomId;
  final String eventId;

  const ChatEvent({
    super.key,
    required this.roomId,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final msg = ref.watch(chatRoomMessageProvider((roomId, eventId)));

    if (msg == null) {
      _log.severe('Msg not found $roomId $eventId');
      return const SizedBox.shrink();
    }

    final inner = msg.eventItem();
    if (inner == null) {
      final virtual = msg.virtualItem();
      if (virtual == null) {
        _log.severe(
          'Event is neither virtual nor full event: $roomId $eventId',
        );
        return const SizedBox.shrink();
      }
      return renderVirtual(msg, virtual);
    }

    return renderEvent(msg: msg, item: inner, ref: ref);
  }

  Widget renderVirtual(RoomMessage msg, RoomVirtualItem virtual) {
    // TODO: virtual Objects support
    return const SizedBox.shrink();
  }

  Widget renderEvent({
    required RoomMessage msg,
    required RoomEventItem item,
    required WidgetRef ref,
  }) {
    final showAvatar = ref.watch(shouldShowAvatarProvider((roomId, eventId)));
    final avatarInfo = ref.watch(
      memberAvatarInfoProvider(
        (
          roomId: roomId,
          userId: item.sender(),
        ),
      ),
    );
    final options = AvatarOptions.DM(avatarInfo, size: 14);
    final myId = ref.watch(myUserIdStrProvider);
    final isUser = myId == item.sender();
    // TODO: render a regular timeline event
    return Row(
      mainAxisAlignment:
          !isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        (showAvatar && !isUser)
            ? Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ActerAvatar(options: options),
              )
            : const SizedBox(width: 40),
        Flexible(
          child: _buildEventItem(msg, item, isUser, showAvatar),
        ),
      ],
    );
  }

  Widget _buildEventItem(
    RoomMessage msg,
    RoomEventItem item,
    bool isUser,
    bool showAvatar,
  ) {
    final eventType = item.eventType();
    switch (eventType) {
      case 'm.room.message':
        return _buildMsgEventItem(roomId, item, msg, isUser, showAvatar);
      case 'm.room.redaction':
        return ChatBubble(
          isUser: isUser,
          showAvatar: showAvatar,
          child: RedactedMessageWidget(),
        );
      case 'm.room.encrypted':
        return ChatBubble(
          isUser: isUser,
          showAvatar: showAvatar,
          child: EncryptedMessageWidget(),
        );
      default:
        return _buildUnsupportedMessage(eventType);
    }
  }

  Widget _buildMsgEventItem(
    String roomId,
    RoomEventItem item,
    RoomMessage msg,
    bool isUser,
    bool showAvatar,
  ) {
    final msgType = item.msgType();
    final content = item.msgContent();
    final messageId = msg.uniqueId();
    // shouldn't happen but in case return empty
    if (msgType == null || content == null) return const SizedBox.shrink();

    switch (msgType) {
      case 'm.emote':
      case 'm.text':
        return TextMessageEvent(
          roomId: roomId,
          content: content,
          isUser: isUser,
          showAvatar: showAvatar,
        );
      case 'm.image':
        return ImageMessageEvent(
          messageId: messageId,
          roomId: roomId,
          content: content,
        );
      case 'm.video':
        return VideoMessageEvent(
          roomId: roomId,
          messageId: messageId,
          content: content,
        );
      case 'm.file':
        return FileMessageEvent(
          roomId: roomId,
          messageId: messageId,
          content: content,
        );
      default:
        return _buildUnsupportedMessage(msgType);
    }
  }

  Widget _buildUnsupportedMessage(String? msgtype) {
    return Text(
      'Unsupported message type: $msgtype',
    );
  }
}
