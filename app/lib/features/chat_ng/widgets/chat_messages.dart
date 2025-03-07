import 'dart:async';

import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/rooms_list.dart';
import 'package:acter/features/chat_ng/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/events/chat_event.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessages extends ConsumerStatefulWidget {
  final String roomId;
  const ChatMessages({super.key, required this.roomId});

  @override
  ConsumerState<ChatMessages> createState() => _ChatMessagesConsumerState();
}

class _ChatMessagesConsumerState extends ConsumerState<ChatMessages> {
  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: true,
  );

  Timer? markReadDebouce;

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
      ).select((value) => value.messageList.length),
      (_, __) {
        if (_scrollController.hasClients &&
            _scrollController.position.pixels >
                _scrollController.position.maxScrollExtent - 150) {
          WidgetsBinding.instance.addPostFrameCallback((_) => scrollToEnd());
        }
      },
    );
    _scrollController.addListener(onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> onScroll() async {
    if (isLoading) return;

    // Check if we're near the top of the list
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent) {
      if (isLoading) return;

      // Get the notifier to load more messages
      final notifier = ref.read(
        chatMessagesStateProvider(widget.roomId).notifier,
      );
      await notifier.loadMore();
    } else if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent) {
      // Unread marking support
      if (!ref.watch(isActiveProvider(LabsFeature.chatUnread))) {
        final roomId = widget.roomId;
        if (ref.read(hasUnreadMessages(roomId)).valueOrNull ?? false) {
          // debounce
          markReadDebouce?.cancel();
          markReadDebouce = Timer(const Duration(milliseconds: 300), () async {
            final timeline = await ref.read(
              timelineStreamProvider(roomId).future,
            );
            await timeline.markAsRead(true);
            markReadDebouce?.cancel();
            markReadDebouce = null;
          });
        }
      }
    }
  }

  void scrollToEnd() {
    if (!mounted || !_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
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
              children: [_buildMessagesList(messages), _buildScrollIndicator()],
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
      reverse: false,
      padding: const EdgeInsets.only(top: 40),
      itemBuilder:
          (_, index, animation) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ChatEvent(roomId: widget.roomId, eventId: messages[index]),
          ),
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
}
