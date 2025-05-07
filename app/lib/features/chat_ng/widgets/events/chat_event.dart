import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat/widgets/messages/encrypted_message.dart';
import 'package:acter/features/chat/widgets/messages/redacted_message.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/chat_bubble.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/profile_changes_event_widget.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/room_membership_event_widget.dart';
import 'package:acter/features/chat_ng/widgets/events/message_event_item.dart';
import 'package:acter/features/chat_ng/widgets/events/room_update_event.dart';
import 'package:acter/features/chat_ng/widgets/events/state_event_container_widget.dart';
import 'package:flutter/material.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem, TimelineItem, TimelineVirtualItem;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat_ng::widgets::room_message');

class ChatEvent extends ConsumerWidget {
  final String roomId;
  final String eventId;

  const ChatEvent({super.key, required this.roomId, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final msg = ref.watch(
      chatRoomMessageProvider((roomId: roomId, uniqueId: eventId)),
    );

    if (msg == null) {
      _log.severe('Msg not found $roomId $eventId');
      return ErrorWidget('Msg not found $roomId $eventId');
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

    return renderExvent(context: context, msg: msg, item: inner, ref: ref);
  }

  Widget renderVirtual(TimelineItem msg, TimelineVirtualItem virtual) {
    // TODO: virtual Objects support
    return const SizedBox.shrink();
  }

  Widget renderExvent({
    required BuildContext context,
    required TimelineItem msg,
    required TimelineEventItem item,
    required WidgetRef ref,
  }) {
    final messageId = msg.uniqueId();
    final myId = ref.watch(myUserIdStrProvider);
    final isMe = myId == item.sender();
    final isDM = ref.watch(isDirectChatProvider(roomId)).valueOrNull ?? false;
    final isFirstMessageBySender = ref.watch(
      isFirstMessageBySenderProvider((roomId: roomId, uniqueId: eventId)),
    );
    final isLastMessageBySender = ref.watch(
      isLastMessageBySenderProvider((roomId: roomId, uniqueId: eventId)),
    );
    final isLastMessage = ref.watch(
      isLastMessageProvider((roomId: roomId, uniqueId: eventId)),
    );
    // FIXME: should check canRedact permission from the room
    final canRedact = item.sender() == myId;
    final eventType = item.eventType();

    final eventWidget = switch (eventType) {
      // handle message inner types separately
      'm.room.message' => MessageEventItem(
        roomId: roomId,
        messageId: messageId,
        item: item,
        isMe: isMe,
        isDM: isDM,
        canRedact: canRedact,
        isFirstMessageBySender: isFirstMessageBySender,
        isLastMessageBySender: isLastMessageBySender,
        isLastMessage: isLastMessage,
      ),
      'MembershipChange' => StateEventContainerWidget(
        child: RoomMembershipEventWidget(
          roomId: roomId,
          eventItem: item,
          textStyle: stateEventTextStyle(context),
        ),
      ),
      'ProfileChange' => StateEventContainerWidget(
        child: ProfileChangesEventWidget(
          roomId: roomId,
          eventItem: item,
          textStyle: stateEventTextStyle(context),
        ),
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
      'm.space.parent' => StateEventContainerWidget(
        child: RoomUpdateEvent(
          isMe: isMe,
          item: item,
          roomId: roomId,
          textStyle: stateEventTextStyle(context),
        ),
      ),
      _ => StateEventContainerWidget(
        child: Text(
          'Unsupported chat event type: $eventType',
          style: stateEventTextStyle(context),
        ),
      ),
    };
    final isMessageEvent = item.eventType() == 'm.room.message';
    return Container(
      padding: EdgeInsets.symmetric(vertical: isFirstMessageBySender ? 12 : 2),
      child: Row(
        mainAxisAlignment:
            !isMessageEvent
                ? MainAxisAlignment.center
                : !isMe
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [eventWidget],
      ),
    );
  }
}
