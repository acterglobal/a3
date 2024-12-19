import 'package:acter/features/chat/utils.dart';
import 'package:acter/features/chat/widgets/messages/encrypted_message.dart';
import 'package:acter/features/chat/widgets/messages/redacted_message.dart';
import 'package:acter/features/chat_ng/widgets/chat_bubble.dart';
import 'package:acter/features/chat_ng/widgets/events/file_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/image_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/member_update_event.dart';
import 'package:acter/features/chat_ng/widgets/events/state_update_event.dart';
import 'package:acter/features/chat_ng/widgets/events/text_message_event.dart';
import 'package:acter/features/chat_ng/widgets/events/video_message_event.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:acter/features/chat_ng/widgets/reply_preview.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomEventItem;
import 'package:flutter/material.dart';

class ChatEventItem extends StatelessWidget {
  final String roomId;
  final String messageId;
  final RoomEventItem item;
  final bool isUser;
  final bool isNextMessageInGroup;
  const ChatEventItem({
    super.key,
    required this.roomId,
    required this.messageId,
    required this.item,
    required this.isUser,
    required this.isNextMessageInGroup,
  });

  @override
  Widget build(BuildContext context) {
    final eventType = item.eventType();

    return switch (eventType) {
      // handle message inner types separately
      'm.room.message' => buildMsgEventItem(
          context,
          roomId,
          messageId,
          item,
        ),
      'm.room.redaction' => isUser
          ? ChatBubble.user(
              context: context,
              isNextMessageInGroup: isNextMessageInGroup,
              child: RedactedMessageWidget(),
            )
          : ChatBubble(
              context: context,
              isNextMessageInGroup: isNextMessageInGroup,
              child: RedactedMessageWidget(),
            ),
      'm.room.encrypted' => isUser
          ? ChatBubble.user(
              context: context,
              isNextMessageInGroup: isNextMessageInGroup,
              child: EncryptedMessageWidget(),
            )
          : ChatBubble(
              context: context,
              isNextMessageInGroup: isNextMessageInGroup,
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
    BuildContext context,
    String roomId,
    String messageId,
    RoomEventItem item,
  ) {
    final msgType = item.msgType();
    final content = item.msgContent();
    // shouldn't happen but in case return empty
    if (msgType == null || content == null) return const SizedBox.shrink();

    return switch (msgType) {
      'm.emote' ||
      'm.notice' ||
      'm.server_notice' ||
      'm.text' =>
        buildTextMsgEvent(context, item),
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

  Widget buildTextMsgEvent(BuildContext context, RoomEventItem item) {
    final msgType = item.msgType();
    final repliedTo = item.inReplyTo();
    final wasEdited = item.wasEdited();
    final content = item.msgContent().expect('cannot be null');
    final isNotice = (msgType == 'm.notice' || msgType == 'm.server_notice');
    Widget? repliedToBuilder;

    // whether it contains `replied to` event.
    if (repliedTo != null) {
      repliedToBuilder =
          RepliedToPreview(roomId: roomId, originalId: repliedTo);
    }

    // if only consists of emojis
    if (isOnlyEmojis(content.body())) {
      return TextMessageEvent.emoji(
        content: content,
        roomId: roomId,
        isUser: isUser,
      );
    }

    late Widget child;
    isNotice
        ? child = TextMessageEvent.notice(content: content, roomId: roomId)
        : child = TextMessageEvent(content: content, roomId: roomId);

    if (isUser) {
      return ChatBubble.user(
        context: context,
        repliedToBuilder: repliedToBuilder,
        isNextMessageInGroup: isNextMessageInGroup,
        isEdited: wasEdited,
        child: child,
      );
    }
    return ChatBubble(
      context: context,
      repliedToBuilder: repliedToBuilder,
      isNextMessageInGroup: isNextMessageInGroup,
      isEdited: wasEdited,
      child: child,
    );
  }

  Widget _buildUnsupportedMessage(String? msgtype) {
    return Text(
      'Unsupported event type: $msgtype',
    );
  }
}
