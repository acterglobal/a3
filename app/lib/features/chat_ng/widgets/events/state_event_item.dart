import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/chat/widgets/messages/encrypted_message.dart';
import 'package:acter/features/chat/widgets/messages/redacted_message.dart';
import 'package:acter/features/chat_ng/models/supported_chat_events.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/chat_bubble.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/profile_changes_event_widget.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/room_membership_event_widget.dart';
import 'package:acter/features/chat_ng/widgets/events/room_update_event.dart';
import 'package:acter/features/chat_ng/widgets/events/state_event_container_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StateEventItem extends ConsumerWidget {
  final String roomId;
  final String eventId;
  final TimelineEventItem item;

  const StateEventItem({
    super.key,
    required this.roomId,
    required this.eventId,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(myUserIdStrProvider);
    final isMe = myId == item.sender();
    final isLastMessageBySender = ref.watch(
      isLastMessageBySenderProvider((roomId: roomId, uniqueId: eventId)),
    );
    final eventType = item.eventType();
    return switch (eventType) {
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
      String type when supportedRoomUpdateStateEvents.contains(type) =>
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
}
