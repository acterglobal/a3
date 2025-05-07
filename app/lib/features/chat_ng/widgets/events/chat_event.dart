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

    return renderEvent(context: context, msg: msg, item: inner, ref: ref);
  }

  Widget renderVirtual(TimelineItem msg, TimelineVirtualItem virtual) {
    // TODO: virtual Objects support
    return const SizedBox.shrink();
  }

  Widget renderEvent({
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
    final canRedact = item.sender() == myId;
    final eventType = item.eventType();

    final eventWidget = _buildEventWidget(
      context: context,
      eventType: eventType,
      roomId: roomId,
      messageId: messageId,
      item: item,
      isMe: isMe,
      isDM: isDM,
      canRedact: canRedact,
      isFirstMessageBySender: isFirstMessageBySender,
      isLastMessageBySender: isLastMessageBySender,
      isLastMessage: isLastMessage,
    );

    final isMessageEvent = eventType == 'm.room.message';
    final mainAxisAlignment =
        !isMessageEvent
            ? MainAxisAlignment.center
            : isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start;

    final messagePadding = EdgeInsets.only(
      top: isFirstMessageBySender ? 12 : 4,
    );

    final stateEventPadding = EdgeInsets.only(
      top: isFirstMessageBySender ? 12 : 4,
      bottom: isLastMessageBySender ? 4 : 12,
    );

    return Padding(
      padding: isMessageEvent ? messagePadding : stateEventPadding,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [eventWidget],
      ),
    );
  }

  Widget _buildEventWidget({
    required BuildContext context,
    required String eventType,
    required String roomId,
    required String messageId,
    required TimelineEventItem item,
    required bool isMe,
    required bool isDM,
    required bool canRedact,
    required bool isFirstMessageBySender,
    required bool isLastMessageBySender,
    required bool isLastMessage,
  }) {
    return switch (eventType) {
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
          textAlign: TextAlign.center,
        ),
      ),
      'ProfileChange' => StateEventContainerWidget(
        child: ProfileChangesEventWidget(
          roomId: roomId,
          eventItem: item,
          textStyle: stateEventTextStyle(context),
          textAlign: TextAlign.center,
        ),
      ),
      'm.room.redaction' => buildChatBubble(
        context,
        const RedactedMessageWidget(),
        isMe,
        isLastMessageBySender,
      ),
      'm.room.encrypted' => buildChatBubble(
        context,
        const EncryptedMessageWidget(),
        isMe,
        isLastMessageBySender,
      ),
      String type when _isSupportedRoomUpdateEvent(type) =>
        StateEventContainerWidget(
          child: RoomUpdateEvent(
            isMe: isMe,
            item: item,
            roomId: roomId,
            textStyle: stateEventTextStyle(context),
            textAlign: TextAlign.center,
          ),
        ),
      _ => StateEventContainerWidget(
        child: Text(
          'Unsupported chat event type: $eventType',
          style: stateEventTextStyle(context),
        ),
      ),
    };
  }

  Widget buildChatBubble(
    BuildContext context,
    Widget child,
    bool isMe,
    bool isLastMessageBySender,
  ) {
    return isMe
        ? ChatBubble.me(
          context: context,
          isLastMessageBySender: isLastMessageBySender,
          child: child,
        )
        : ChatBubble(
          context: context,
          isLastMessageBySender: isLastMessageBySender,
          child: child,
        );
  }

  bool _isSupportedRoomUpdateEvent(String type) {
    const supportedRoomUpdateEvents = {
      'm.policy.rule.room',
      'm.policy.rule.server',
      'm.policy.rule.user',
      'm.room.aliases',
      'm.room.avatar',
      'm.room.canonical_alias',
      'm.room.create',
      'm.room.encryption',
      'm.room.guest_access',
      'm.room.history_visibility',
      'm.room.join_rules',
      'm.room.name',
      'm.room.pinned_events',
      'm.room.power_levels',
      'm.room.server_acl',
      'm.room.third_party_invite',
      'm.room.tombstone',
      'm.room.topic',
      'm.space.child',
      'm.space.parent',
    };
    return supportedRoomUpdateEvents.contains(type);
  }
}
