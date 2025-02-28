import 'dart:async';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/features/chat_ng/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::chat::room_notifier');

class ChatRoomMessagesNotifier extends StateNotifier<ChatRoomState> {
  final Ref ref;
  final String roomId;
  late GlobalKey<AnimatedListState> _listState;
  late TimelineStream timeline;
  late Stream<RoomMessageDiff> _listener;
  late StreamSubscription<RoomMessageDiff> _poller;

  ChatRoomMessagesNotifier({
    required this.roomId,
    required this.ref,
  }) : super(const ChatRoomState()) {
    _init();
  }

  GlobalKey<AnimatedListState> get animatedList => _listState;

  Future<void> _init() async {
    _listState = GlobalKey<AnimatedListState>(
      debugLabel: '$roomId-chat-message-animated-list-state',
    );
    try {
      timeline = await ref.read(timelineStreamProvider(roomId).future);
      _listener = timeline.messagesStream(); // keep it resident in memory
      _poller = _listener.listen(
        (diff) {
          state = handleDiff(state, _listState.currentState, diff);
        },
        onError: (e, s) {
          _log.severe('msg stream errored', e, s);
        },
        onDone: () {
          _log.info('msg stream ended');
        },
      );
      ref.onDispose(() async {
        _poller.cancel();
        await timeline.cancelStream();
      });
      do {
        await loadMore(failOnError: true);
        await Future.delayed(const Duration(milliseconds: 200), () => null);
      } while (state.hasMore && state.messageList.length < 10);
    } catch (e, s) {
      _log.severe('Error loading more messages', e, s);
      state = state.copyWith(
        loading: ChatRoomLoadingState.error(e.toString()),
      );
    }
  }

  Future<void> loadMore({bool failOnError = false}) async {
    if (state.hasMore && !state.loading.isLoading) {
      try {
        state = state.copyWith(
          loading: const ChatRoomLoadingState.loading(),
        );
        final hasMore = !await timeline.paginateBackwards(20);
        // wait for diffRx to be finished
        state = state.copyWith(
          hasMore: hasMore,
          loading: const ChatRoomLoadingState.loaded(),
        );
      } catch (e, s) {
        _log.severe('Error loading more messages', e, s);
        state = state.copyWith(
          loading: ChatRoomLoadingState.error(e.toString()),
        );
        if (failOnError) {
          rethrow;
        }
      }
    }
  }
}

@visibleForTesting
ChatRoomState handleDiff(
  ChatRoomState state, // the current state
  AnimatedListState? animatedList, // the animated list connected to this state
  RoomMessageDiff diff, // the diff to apply
) {
  final action = diff.action();
  switch (action) {
    case 'Append':
      List<RoomMessage> incoming =
          diff.values().expect('append diff must contain values').toList();

      final messageList = state.messageList.toList();
      final startLen = messageList.length;
      final messages = Map.fromEntries(state.messages.entries);

      for (final m in incoming) {
        final uniqueId = m.uniqueId();
        messages[uniqueId] = m;
        messageList.add(uniqueId);
      }
      final endLen = messageList.length;
      animatedList?.insertAllItems(startLen, endLen - startLen);
      return state.copyWith(
        messageList: messageList,
        messages: messages,
      );
    case 'Set': // used to update UnableToDecrypt message
      RoomMessage m = diff.value().expect('set diff must contain value');
      final index = diff.index().expect('set diff must contain index');

      final uniqueId = m.uniqueId();
      if (state.messageList.isEmpty) {
        animatedList?.insertItem(0);
        return state.copyWith(
          messageList: [uniqueId],
          messages: {uniqueId: m},
        );
      }
      final messageList = state.messageList.toList();
      final removedItem = messageList.removeAt(index);
      messageList.insert(index, uniqueId);

      final messages = Map.fromEntries(
        state.messages.entries.where((entry) => entry.key != removedItem),
      );
      messages[uniqueId] = m;
      return state.copyWith(
        messageList: messageList,
        messages: messages,
      );
    case 'Insert':
      RoomMessage m = diff.value().expect('insert diff must contain value');
      final index = diff.index().expect('insert diff must contain index');
      return state.copyWithNewMessageAt(index, m, animatedList);
    case 'Remove':
      int index = diff.index().expect('remove diff must contain index');
      return state.copyWithRemovedMessageAt(index, animatedList);
    case 'PushBack':
      RoomMessage m = diff.value().expect('push back diff must contain value');

      if (state.messageList.isEmpty) {
        final uniqueId = m.uniqueId();
        animatedList?.insertItem(0);
        return state.copyWith(messageList: [uniqueId], messages: {uniqueId: m});
      }
      return state.copyWithNewMessageAt(
        state.messageList.length,
        m,
        animatedList,
      );
    case 'PushFront':
      RoomMessage m = diff.value().expect('push front diff must contain value');
      return state.copyWithNewMessageAt(0, m, animatedList);
    case 'PopBack':
      if (state.messageList.isEmpty) {
        return state;
      }
      return state.copyWithRemovedMessageAt(
        state.messageList.length - 1,
        animatedList,
      );
    case 'PopFront':
      return state.copyWithRemovedMessageAt(0, animatedList);
    case 'Clear':
      if (state.messageList.isNotEmpty && animatedList != null) {
        animatedList.removeAllItems((b, a) => const SizedBox.shrink());
      }
      return state.copyWith(messageList: [], messages: {});
    case 'Reset':
      List<RoomMessage> incoming =
          diff.values().expect('reset diff must contain values').toList();
      final (messageList, messages) = incoming
          .fold((List<String>.empty(growable: true), <String, RoomMessage>{}),
              (val, m) {
        final (list, map) = val;
        final uniqueId = m.uniqueId();
        list.add(uniqueId);
        map[uniqueId] = m;
        return (list, map);
      });
      if (animatedList != null) {
        animatedList.removeAllItems((b, a) => const SizedBox.shrink());
        animatedList.insertAllItems(0, messageList.length);
      }
      return state.copyWith(
        messageList: messageList,
        messages: messages,
      );
    case 'Truncate':
      if (state.messageList.isEmpty) {
        return state;
      }
      final index = diff.index().expect('truncate diff must contain index');

      final (before, after) =
          state.messageList.fold((<String>[], <String>[]), (f, e) {
        final (before, after) = f;
        if (before.length >= index) {
          after.add(e);
        } else {
          before.add(e);
        }
        return (before, after);
      });
      if (after.isEmpty) {
        animatedList?.removeAllItems((a, b) => const SizedBox.shrink());
        return state.copyWith(
          messageList: before,
          messages: Map.fromEntries(
            state.messages.entries,
          ),
        );
      } else {
        if (animatedList != null) {
          for (var x = state.messageList.length; x >= after.length; x--) {
            // remove from the bottom up
            animatedList.removeItem(x - 1, (a, b) => const SizedBox.shrink());
          }
        }
        // we have to remove some
        final messages = Map.fromEntries(
          state.messages.entries.where((entry) => !after.contains(entry.key)),
        );
        return state.copyWith(messageList: before, messages: messages);
      }
    default:
      _log.severe('Unsupported action $action when diffing room messages');
      break;
  }
  return state;
}
