import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/events/chat_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessages extends ConsumerStatefulWidget {
  final String roomId;
  const ChatMessages({super.key, required this.roomId});

  @override
  ConsumerState<ChatMessages> createState() => _ChatMessagesConsumerState();
}

class _ChatMessagesConsumerState extends ConsumerState<ChatMessages> {
  final ScrollController _scrollController = ScrollController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });
  }

  Future<void> onScroll() async {
    if (isLoading) return;

    // Check if we're near the top of the list
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent) {
      setState(() => isLoading = true);

      // Get the notifier to load more messages
      final notifier = ref.read(chatStateProvider(widget.roomId).notifier);
      await notifier.loadMore();

      setState(() => isLoading = false);
    }
  }

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(
      chatStateProvider(widget.roomId).select((value) => value.messageList),
    );
    final animatedListKey =
        ref.watch(animatedListChatMessagesProvider(widget.roomId));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isLoading ? 14 : 0,
            width: isLoading ? 14 : 0,
            child: Center(
              child: isLoading ? const CircularProgressIndicator() : null,
            ),
          ),
        ),
        // Messages list takes remaining space
        Expanded(
          child: AnimatedList(
            initialItemCount: messages.length,
            key: animatedListKey,
            controller: _scrollController,
            reverse: true,
            itemBuilder: (_, index, animation) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ChatEvent(
                roomId: widget.roomId,
                eventId: messages[messages.length - 1 - index],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
