import 'dart:async';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat/providers/chat_providers.dart' as chat;
import 'package:acter/features/chat/widgets/rooms_list.dart';
import 'package:acter/features/chat_ng/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/events/chat_event.dart';
import 'package:acter/common/widgets/typing_indicator.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class ChatMessages extends ConsumerStatefulWidget {
  static const fabScrollToBottomKey = Key('chat_messages_fab_scroll_to_bottom');
  final String roomId;
  const ChatMessages({super.key, required this.roomId});

  @override
  ConsumerState<ChatMessages> createState() => ChatMessagesConsumerState();
}

class ChatMessagesConsumerState extends ConsumerState<ChatMessages> {
  final ScrollController _scrollController = AutoScrollController(
    initialScrollOffset: 0.0,
  );

  Timer? markReadDebouce;
  bool showScrollToBottom = false;

  bool get isLoading => ref.watch(
    chatMessagesStateProvider(widget.roomId).select((v) => v.loading.isLoading),
  );

  @override
  void initState() {
    super.initState();
    // for first time messages load, should scroll at the latest (bottom)
    ref.listenManual(
      chatMessagesStateProvider(
        widget.roomId,
      ).select((value) => value.messageList),
      (prev, current) {
        if (prev == null && current.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) => scrollToEnd());
        }
      },
    );

    _scrollController.addListener(onScroll);
  }

  @override
  void dispose() {
    markReadDebouce?.cancel();
    _scrollController.dispose();

    super.dispose();
  }

  Future<void> onScroll() async {
    if (isLoading) return;

    // Check if we're near the bottom of the list (which is now the top of the chat history)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent) {
      if (isLoading) return;

      // Get the notifier to load more messages
      final notifier = ref.read(
        chatMessagesStateProvider(widget.roomId).notifier,
      );
      await notifier.loadMore();
    } else if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent) {
      // Unread marking support
      if (!ref.watch(isActiveProvider(LabsFeature.chatUnread))) {
        final roomId = widget.roomId;
        if (ref.read(chat.hasUnreadMessages(roomId)).valueOrNull ?? false) {
          // debounce
          markReadDebouce?.cancel();
          markReadDebouce = Timer(const Duration(milliseconds: 300), () async {
            final timeline = await ref.read(
              chat.timelineStreamProvider(roomId).future,
            );
            await timeline.markAsRead(true);
            markReadDebouce?.cancel();
            markReadDebouce = null;
          });
        }
      }
    }

    // Update scroll to bottom button visibility
    final shouldShowButton =
        _scrollController.hasClients &&
        _scrollController.position.pixels >
            (_scrollController.position.minScrollExtent + 5);

    if (shouldShowButton != showScrollToBottom) {
      setState(() {
        showScrollToBottom = shouldShowButton;
      });
    }
  }

  void scrollToEnd() {
    if (!mounted || !_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(
      chatMessagesStateProvider(
        widget.roomId,
      ).select((value) => value.messageList),
    );

    return PageStorage(
      bucket: bucketGlobal,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _buildMessagesList(messages),
                _buildScrollIndicator(),
                _buildScrollToBottomButton(),
                _buildTypingIndicator(ref, widget.roomId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<String> messages) => KeyedSubtree(
    key: PageStorageKey('chat_list_${widget.roomId}'),
    child: AnimatedList(
      initialItemCount: messages.length,
      key: ref.watch(animatedListChatMessagesProvider(widget.roomId)),
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.only(bottom: 40),
      itemBuilder:
          (_, index, animation) =>
              ChatEvent(roomId: widget.roomId, eventId: messages[index]),
    ),
  );

  Widget _buildScrollIndicator() => Positioned(
    top: 12,
    left: 0,
    right: 0,
    child: Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: isLoading ? 14 : 0,
        width: isLoading ? 14 : 0,
        child: Center(
          child: isLoading ? const CircularProgressIndicator() : null,
        ),
      ),
    ),
  );

  //  scroll indicator widget
  Widget _buildScrollToBottomButton() => Positioned(
    key: ChatMessages.fabScrollToBottomKey,
    bottom: 16,
    right: 16,
    child: AnimatedOpacity(
      opacity: showScrollToBottom ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedScale(
        scale: showScrollToBottom ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton(
          mini: true,
          onPressed: showScrollToBottom ? scrollToEnd : null,
          child: const Icon(Icons.arrow_downward),
        ),
      ),
    ),
  );
}

Widget _buildTypingIndicator(WidgetRef ref, String roomId) {
  final typingUsers =
      (ref.watch(chatTypingEventProvider(roomId)).valueOrNull ?? [])
          .map(
            (userId) => ref.watch(
              memberAvatarInfoProvider((userId: userId, roomId: roomId)),
            ),
          )
          .toList();
  if (typingUsers.isEmpty) return const SizedBox.shrink();
  return Positioned(
    bottom: 16,
    left: 16,
    right: 0,
    child: TypingIndicator(
      options: TypingIndicatorOptions(typingUsers: typingUsers),
    ),
  );
}
