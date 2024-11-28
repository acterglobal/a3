import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/events/chat_event.dart';
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
      key: animatedListKey,
      itemBuilder: (_, index, animation) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ChatEvent(
          roomId: roomId,
          eventId: messages[index],
        ),
      ),
    );
  }
}
