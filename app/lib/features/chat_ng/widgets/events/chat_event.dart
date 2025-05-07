import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/chat_ng/models/supported_chat_events.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/events/message_event_item.dart';
import 'package:acter/features/chat_ng/widgets/events/state_event_container_widget.dart';
import 'package:acter/features/chat_ng/widgets/events/state_event_item.dart';
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
    final isFirstMessageBySender = ref.watch(
      isFirstMessageBySenderProvider((roomId: roomId, uniqueId: eventId)),
    );
    final isLastMessageBySender = ref.watch(
      isLastMessageBySenderProvider((roomId: roomId, uniqueId: eventId)),
    );
    final eventType = item.eventType();

    final eventWidget = switch (eventType) {
      'm.room.message' => MessageEventItem(
        roomId: roomId,
        messageId: messageId,
        item: item,
        isMe: isMe,
        isFirstMessageBySender: isFirstMessageBySender,
        isLastMessageBySender: isLastMessageBySender,
      ),
      String type when supportedStateEventTypes.contains(type) =>
        StateEventItem(roomId: roomId, eventId: eventId, item: item),
      _ => StateEventContainerWidget(
        child: Text(
          'Unsupported chat event type: $eventType',
          style: stateEventTextStyle(context),
        ),
      ),
    };

    final isMessageEvent = eventType == 'm.room.message';
    final mainAxisAlignment =
        !isMessageEvent
            ? MainAxisAlignment.center
            : isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start;

    final messagePadding = EdgeInsets.only(
      top: isFirstMessageBySender ? 16 : 4,
      bottom: 4,
    );

    final stateEventPadding = const EdgeInsets.symmetric(vertical: 8);

    return Padding(
      padding: isMessageEvent ? messagePadding : stateEventPadding,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [eventWidget],
      ),
    );
  }
}
