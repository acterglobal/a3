import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::widgets::room_message');

class ChatEventWidget extends ConsumerWidget {
  final RoomMessage? message;
  final String roomId;
  final String eventId;
  final Animation<double>? animation;

  const ChatEventWidget({
    super.key,
    required this.roomId,
    required this.eventId,
    this.message,
    this.animation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final msg =
        message ?? ref.watch(chatRoomMessageProvider((roomId, eventId)));
    if (msg == null) {
      _log.severe('Msg not found $roomId $eventId');
      return const SizedBox.shrink();
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

    return renderEvent(msg, inner);
  }

  Widget renderVirtual(RoomMessage msg, RoomVirtualItem virtual) {
    // TODO: virtual Objects support
    return const SizedBox.shrink();
  }

  Widget renderEvent(RoomMessage msg, RoomEventItem item) {
    // TODO: render a regular timeline event
    return Wrap(
      children: [
        Text(item.sender()),
        const Text(':'),
        Text(item.msgContent()?.body() ?? 'no body'),
      ],
    );
  }
}
