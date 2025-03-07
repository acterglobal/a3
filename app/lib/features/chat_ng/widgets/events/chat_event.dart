import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/utils.dart';
import 'package:acter/features/chat_ng/widgets/events/chat_event_item.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomMessage, RoomVirtualItem, RoomEventItem;
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

    return renderEvent(ctx: context, msg: msg, item: inner, ref: ref);
  }

  Widget renderVirtual(RoomMessage msg, RoomVirtualItem virtual) {
    // TODO: virtual Objects support
    return const SizedBox.shrink();
  }

  Widget renderEvent({
    required BuildContext ctx,
    required RoomMessage msg,
    required RoomEventItem item,
    required WidgetRef ref,
  }) {
    final isLastMessageBySender = ref.watch(
      isLastMessageBySenderProvider((roomId: roomId, uniqueId: eventId)),
    );
    final isFirstMessageBySender = ref.watch(
      isFirstMessageBySenderProvider((roomId: roomId, uniqueId: eventId)),
    );
    final myId = ref.watch(myUserIdStrProvider);
    final messageId = msg.uniqueId();
    // FIXME: should check canRedact permission from the room
    final canRedact = item.sender() == myId;

    final isMe = myId == item.sender();

    final bool shouldShowAvatar = _shouldShowAvatar(
      eventType: item.eventType(),
      isLastMessageBySender: isLastMessageBySender,
      isMe: isMe,
    );
    return Padding(
      padding: EdgeInsets.only(
        top: isFirstMessageBySender ? 12 : 2,
        bottom: isLastMessageBySender ? 12 : 2,
      ),
      child: Row(
        mainAxisAlignment:
            !isMe ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          shouldShowAvatar
              ? Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ActerAvatar(
                  options: AvatarOptions.DM(
                    ref.watch(
                      memberAvatarInfoProvider((
                        roomId: roomId,
                        userId: item.sender(),
                      ),),
                    ),
                    size: 14,
                  ),
                ),
              )
              : const SizedBox(width: 40),
          Flexible(
            child: ChatEventItem(
              roomId: roomId,
              messageId: messageId,
              item: item,
              isMe: isMe,
              canRedact: canRedact,
              isFirstMessageBySender: isFirstMessageBySender,
              isLastMessageBySender: isLastMessageBySender,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowAvatar({
    required String eventType,
    required bool isLastMessageBySender,
    required bool isMe,
  }) {
    if (isStateEvent(eventType) || isMemberEvent(eventType)) {
      return !isMe; // Show avatar only for state messages
    }
    // For regular messages, follow the grouping
    return isLastMessageBySender && !isMe;
  }
}
