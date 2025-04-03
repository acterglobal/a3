import 'package:acter/features/chat/widgets/messages/encrypted_message.dart';
import 'package:acter/features/chat/widgets/messages/redacted_message.dart';
import 'package:acter/features/chat_ng/widgets/chat_bubble.dart';
import 'package:acter/features/chat_ng/widgets/events/member_update_event.dart';
import 'package:acter/features/chat_ng/widgets/events/message_event_item.dart';
import 'package:acter/features/chat_ng/widgets/events/room_update_event.dart';

import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem;
import 'package:flutter/material.dart';

class ChatEventItem extends StatelessWidget {
  final String roomId;
  final String messageId;
  final TimelineEventItem item;
  final bool isMe;
  final bool canRedact;
  final bool isFirstMessageBySender;
  final bool isLastMessageBySender;
  final bool isLastMessage;
  const ChatEventItem({
    super.key,
    required this.roomId,
    required this.messageId,
    required this.item,
    required this.isMe,
    required this.canRedact,
    required this.isFirstMessageBySender,
    required this.isLastMessageBySender,
    required this.isLastMessage,
  });

  @override
  Widget build(BuildContext context) {
    final eventType = item.eventType();
    return switch (eventType) {
      // handle message inner types separately
      'm.room.message' => MessageEventItem(
        roomId: roomId,
        messageId: messageId,
        item: item,
        isMe: isMe,
        canRedact: canRedact,
        isFirstMessageBySender: isFirstMessageBySender,
        isLastMessageBySender: isLastMessageBySender,
        isLastMessage: isLastMessage,
      ),
      'm.room.redaction' =>
        isMe
            ? ChatBubble.me(
              context: context,
              isLastMessageBySender: isLastMessageBySender,
              child: RedactedMessageWidget(),
            )
            : ChatBubble(
              context: context,
              isLastMessageBySender: isLastMessageBySender,
              child: RedactedMessageWidget(),
            ),
      'm.room.encrypted' =>
        isMe
            ? ChatBubble.me(
              context: context,
              isLastMessageBySender: isLastMessageBySender,
              child: EncryptedMessageWidget(),
            )
            : ChatBubble(
              context: context,
              isLastMessageBySender: isLastMessageBySender,
              child: EncryptedMessageWidget(),
            ),
      'm.room.member' || 'ProfileChange' => MemberUpdateEvent(
        isMe: isMe,
        roomId: roomId,
        item: item,
      ),
      'm.policy.rule.room' ||
      'm.policy.rule.server' ||
      'm.policy.rule.user' ||
      'm.poll.start' ||
      'm.room.create' ||
      'm.room.aliases' ||
      'm.room.avatar' ||
      'm.room.canonical_alias' ||
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
      'm.space.parent' => RoomUpdateEvent(
        isMe: isMe,
        item: item,
        roomId: roomId,
      ),
      _ => _buildUnsupportedMessage(eventType),
    };
  }

  Widget _buildUnsupportedMessage(String? msgtype) {
    return Text('Unsupported chat event type: $msgtype');
  }
}
