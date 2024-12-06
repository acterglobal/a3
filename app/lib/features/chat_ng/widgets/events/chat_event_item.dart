import 'package:acter/features/chat/widgets/messages/encrypted_message.dart';
import 'package:acter/features/chat/widgets/messages/redacted_message.dart';
import 'package:acter/features/chat_ng/widgets/chat_bubble.dart';
import 'package:acter/features/chat_ng/widgets/events/file_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/image_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/member_update_event.dart';
import 'package:acter/features/chat_ng/widgets/events/state_update_event.dart';
import 'package:acter/features/chat_ng/widgets/events/text_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/video_message_event.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomEventItem;
import 'package:flutter/material.dart';

class ChatEventItem extends StatelessWidget {
  final String roomId;
  final String messageId;
  final RoomEventItem item;
  final bool isUser;
  final bool nextMessageGroup;
  const ChatEventItem({
    super.key,
    required this.roomId,
    required this.messageId,
    required this.item,
    required this.isUser,
    required this.nextMessageGroup,
  });

  @override
  Widget build(BuildContext context) {
    final eventType = item.eventType();
    return switch (eventType) {
      // handle message inner types separately
      'm.room.message' => buildMsgEventItem(
          roomId,
          messageId,
          item,
          isUser,
          nextMessageGroup,
        ),
      'm.room.redaction' => isUser
          ? ChatBubble.user(
              context: context,
              nextMessageGroup: nextMessageGroup,
              child: RedactedMessageWidget(),
            )
          : ChatBubble(
              context: context,
              nextMessageGroup: nextMessageGroup,
              child: RedactedMessageWidget(),
            ),
      'm.room.encrypted' => isUser
          ? ChatBubble.user(
              context: context,
              nextMessageGroup: nextMessageGroup,
              child: EncryptedMessageWidget(),
            )
          : ChatBubble(
              context: context,
              nextMessageGroup: nextMessageGroup,
              child: EncryptedMessageWidget(),
            ),
      'm.room.member' => MemberUpdateEvent(
          isUser: isUser,
          item: item,
        ),
      'm.policy.rule.room' ||
      'm.policy.rule.server' ||
      'm.policy.rule.user' ||
      'm.room.aliases' ||
      'm.room.avatar' ||
      'm.room.canonical_alias' ||
      'm.room.create' ||
      'm.room.encryption' ||
      'm.room.guest_access' ||
      'm.room.history_visibility' ||
      'm.room.join_rules' ||
      'm.room.name' ||
      'm.room.pinned_events' ||
      'm.room.power_levels' ||
      'm.room.server_acl' ||
      'm.room.third_party_invite' ||
      'm.room.tombstone' ||
      'm.room.topic' ||
      'm.space.child' ||
      'm.space.parent' =>
        StateUpdateEvent(item: item),
      _ => _buildUnsupportedMessage(eventType),
    };
  }

  Widget buildMsgEventItem(
    String roomId,
    String messageId,
    RoomEventItem item,
    bool isUser,
    bool showAvatar,
  ) {
    final msgType = item.msgType();
    final content = item.msgContent();

    // shouldn't happen but in case return empty
    if (msgType == null || content == null) return const SizedBox.shrink();

    return switch (msgType) {
      'm.emote' || 'm.text' => TextMessageEvent(
          roomId: roomId,
          content: content,
          isUser: isUser,
          nextMessageGroup: showAvatar,
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
