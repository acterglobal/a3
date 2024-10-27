import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessages extends ConsumerWidget {
  final String roomId;
  const ChatMessages({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref
        .watch(chatStateProvider(roomId).select((value) => value.messageList));
    final animatedListKey = ref.watch(animatedListChatMessagesProvider(roomId));

    return AnimatedList(
      initialItemCount: messages.length,
      reverse: true,
      key: animatedListKey,
      itemBuilder: (_, index, animation) => _messageBuilder(
        ref.watch(
          chatRoomMessageProvider((roomId, messages[index])),
        ),
        animation,
      ),
    );
  }

  Widget _messageBuilder(RoomMessage? msg, Animation<double> animation) {
    final inner = msg?.eventItem();
    if (inner == null) {
      return const SizedBox.shrink();
    }
    return Wrap(
      children: [
        Text(inner.sender()),
        const Text(':'),
        Text(inner.msgContent()?.body() ?? 'no body'),
      ],
    );
  }
}
