import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/events/chat_event_item.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomMessage, RoomVirtualItem, RoomEventItem;
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
    final nextMessageGroup =
        ref.watch(isNextMessageGroupProvider((roomId, eventId)));
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
    final messageId = msg.uniqueId();
    final isUser = myId == item.sender();
    // TODO: render a regular timeline event
    return Row(
      mainAxisAlignment:
          !isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        (nextMessageGroup && !isUser)
            ? Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ActerAvatar(options: options),
              )
            : const SizedBox(width: 40),
        Flexible(
          child: ChatEventItem(
            roomId: roomId,
            messageId: messageId,
            item: item,
            isUser: isUser,
            nextMessageGroup: nextMessageGroup,
          ),
        ),
      ],
    );
  }
}
