import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/config/constants.dart';
import 'package:acter/features/chat/widgets/messages/encrypted_message.dart';
import 'package:acter/features/chat/widgets/messages/redacted_message.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/chat_bubble.dart';
import 'package:acter/features/chat_ng/widgets/events/profile_changes_event_widget.dart';
import 'package:acter/features/chat_ng/widgets/events/room_membership_event_widget.dart';
import 'package:acter/features/chat_ng/widgets/events/message_event_item.dart';
import 'package:acter/features/chat_ng/widgets/events/room_update_event.dart';
import 'package:acter/features/chat_ng/widgets/events/state_event_container_widget.dart';
import 'package:acter/features/chat_ng/widgets/read_receipts_widget.dart';
import 'package:acter/features/member/dialogs/show_member_info_drawer.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem, TimelineItem, TimelineVirtualItem;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat_ng::widgets::room_message');

/// Set of supported room update event types
const _supportedRoomUpdateEvents = {
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
    final hasReadReceipts =
        ref.watch(messageReadReceiptsProvider(item)).isNotEmpty;

    final canRedact = item.sender() == myId;
    final eventType = item.eventType();

    final eventWidget = switch (eventType) {
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
        ref,
        const RedactedMessageWidget(),
        item.sender(),
        isMe,
        isDM,
        isFirstMessageBySender,
        isLastMessageBySender,
      ),
      'm.room.encrypted' => buildChatBubble(
        context,
        ref,
        const EncryptedMessageWidget(),
        item.sender(),
        isMe,
        isDM,
        isFirstMessageBySender,
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
      _ =>
        isNightly || isDevBuild
            ? StateEventContainerWidget(
              child: Text(
                L10n.of(context).unsupportedChatEventType(eventType),
                style: stateEventTextStyle(context),
              ),
            )
            : const SizedBox.shrink(),
    };

    final isBubbleEvent =
        eventType == 'm.room.message' ||
        eventType == 'm.room.redaction' ||
        eventType == 'm.room.encrypted';

    final mainAxisAlignment =
        !isBubbleEvent
            ? MainAxisAlignment.center
            : isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start;

    return Padding(
      padding:
          isBubbleEvent
              ? EdgeInsets.only(top: isFirstMessageBySender ? 20 : 4)
              : const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildAvatar(
                context,
                ref,
                roomId,
                item.sender(),
                isMe,
                isLastMessageBySender,
                isBubbleEvent,
                isDM,
              ),
              eventWidget,
            ],
          ),
          if (hasReadReceipts)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: ReadReceiptsWidget(
                item: item,
                roomId: roomId,
                messageId: messageId,
              ),
            ),
        ],
      ),
    );
  }

  Widget buildChatBubble(
    BuildContext context,
    WidgetRef ref,
    Widget child,
    String senderId,
    bool isMe,
    bool isDM,
    bool isFirstMessageBySender,
    bool isLastMessageBySender,
  ) {
    String? displayName;
    if (isFirstMessageBySender && !isMe && !isDM) {
      final letRoomId = roomId;
      displayName =
          ref
              .watch(
                memberDisplayNameProvider((
                  userId: senderId,
                  roomId: letRoomId,
                )),
              )
              .valueOrNull ??
          senderId;
    }

    return isMe
        ? ChatBubble.me(
          context: context,
          isFirstMessageBySender: isFirstMessageBySender,
          isLastMessageBySender: isLastMessageBySender,
          displayName: displayName,
          child: child,
        )
        : ChatBubble(
          context: context,
          isFirstMessageBySender: isFirstMessageBySender,
          isLastMessageBySender: isLastMessageBySender,
          displayName: displayName,
          child: child,
        );
  }

  bool _isSupportedRoomUpdateEvent(String type) {
    return _supportedRoomUpdateEvents.contains(type);
  }

  Widget _buildAvatar(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    String userId,
    bool isMe,
    bool isLastMessageBySender,
    bool isBubbleEvent,
    bool isDM,
  ) {
    if (_shouldShowAvatar(
      isLastMessageBySender: isLastMessageBySender,
      isBubbleEvent: isBubbleEvent,
      isMe: isMe,
      isDM: isDM,
    )) {
      return Padding(
        padding: EdgeInsets.only(right: isMe ? 8 : 0, left: isMe ? 0 : 8),
        child: GestureDetector(
          onTap:
              () => showMemberInfoDrawer(
                context: context,
                roomId: roomId,
                memberId: userId,
              ),
          child: ActerAvatar(
            options: AvatarOptions.DM(
              ref.watch(
                memberAvatarInfoProvider((roomId: roomId, userId: userId)),
              ),
              size: 14,
            ),
          ),
        ),
      );
    } else if (_shouldShowSpacer(isMe: isMe, isDM: isDM)) {
      return const SizedBox(width: 36);
    }

    return const SizedBox.shrink();
  }

  /// Determines whether to show the avatar in the chat message.
  ///
  /// Returns true if all the following conditions are met:
  /// * It's the last message by the sender
  /// * It's a bubble event (like a text message)
  /// * Message is not from the logged-in user (not mine)
  /// * The chat is not a direct message
  ///
  /// Parameters:
  /// * [isLastMessageBySender] - Whether this is the last message from this sender
  /// * [isBubbleEvent] - Whether this is a bubble-type message event
  /// * [isMe] - Whether the message is from the logged-in user
  /// * [isDM] - Whether this is a direct message chat
  bool _shouldShowAvatar({
    required bool isLastMessageBySender,
    required bool isBubbleEvent,
    required bool isMe,
    required bool isDM,
  }) {
    return isLastMessageBySender && isBubbleEvent && !isMe && !isDM;
  }

  /// Determines whether to show a spacer in place of an avatar.
  ///
  /// Returns true if the message is:
  /// * Message is not from the logged-in user (not mine)
  /// * Not in a direct message chat
  ///
  /// Parameters:
  /// * [isMe] - Whether the message is from the logged-in user
  /// * [isDM] - Whether this is a direct message chat
  bool _shouldShowSpacer({required bool isMe, required bool isDM}) {
    return !isMe && !isDM;
  }
}
