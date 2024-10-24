import 'dart:async';
import 'dart:collection';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/features/chat_ng/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::chat::room_notifier');

class ChatRoomMessagesNotifier extends StateNotifier<ChatRoomState> {
  final Ref ref;
  final String roomId;
  late TimelineStream timeline;
  late Stream<RoomMessageDiff> _listener;
  late StreamSubscription<RoomMessageDiff> _poller;

  ChatRoomMessagesNotifier({
    required this.roomId,
    required this.ref,
  }) : super(const ChatRoomState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      timeline = await ref.read(timelineStreamProvider(roomId).future);
      _listener = timeline.messagesStream(); // keep it resident in memory
      _poller = _listener.listen(
        _executeDiff,
        onError: (e, s) {
          _log.severe('msg stream errored', e, s);
        },
        onDone: () {
          _log.info('msg stream ended');
        },
      );
      ref.onDispose(() => _poller.cancel());
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

  void _executeDiff(RoomMessageDiff diff) {}

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

// List<RoomMessage> messagesCopy() => List.from(state.messages, growable: true);

// // Messages CRUD
// void setMessages(List<RoomMessage> messages) =>
//     state = state.copyWith(messages: messages);

// void insertMessage(int to, RoomMessage m) {
//   final newState = messagesCopy();
//   if (to < newState.length) {
//     newState.insert(to, m);
//   } else {
//     newState.add(m);
//   }
//   state = state.copyWith(messages: newState);
// }

// void replaceMessageAt(int index, RoomMessage m) {
//   WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
//     final newState = messagesCopy();
//     newState[index] = m;
//     state = state.copyWith(messages: newState);
//   });
// }

// void removeMessage(int idx) {
//   final newState = messagesCopy();
//   newState.removeAt(idx);
//   state = state.copyWith(messages: newState);
// }

// void resetMessages() => state = state.copyWith(messages: []);

// parses `RoomMessage` event to `RoomMessage` and updates messages list
@visibleForTesting
ChatRoomState handleDiff(ChatRoomState state, RoomMessageDiff diff) {
  switch (diff.action()) {
    case 'Append':
      List<RoomMessage> incoming =
          diff.values().expect('append diff must contain values').toList();

      final messageList = state.messageList.toList();
      final messages = Map.fromEntries(state.messages.entries);

      for (final m in incoming) {
        final uniqueId = m.uniqueId();
        messages[uniqueId] = m;
        messageList.add(uniqueId);
      }
      return state.copyWith(
        messageList: messageList,
        messages: messages,
      );
    case 'Set': // used to update UnableToDecrypt message
      RoomMessage m = diff.value().expect('set diff must contain value');
      final index = diff.index().expect('set diff must contain index');

      final uniqueId = m.uniqueId();
      if (state.messageList.isEmpty) {
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
      return state.copyWithNewMessageAt(index, m);
    case 'Remove':
      int index = diff.index().expect('remove diff must contain index');
      return state.copyWithRemovedMessageAt(index);
    case 'PushBack':
      RoomMessage m = diff.value().expect('push back diff must contain value');

      if (state.messageList.isEmpty) {
        final uniqueId = m.uniqueId();
        return state.copyWith(messageList: [uniqueId], messages: {uniqueId: m});
      }
      return state.copyWithNewMessageAt(state.messageList.length, m);
    case 'PushFront':
      RoomMessage m = diff.value().expect('push front diff must contain value');
      return state.copyWithNewMessageAt(0, m);
    case 'PopBack':
      if (state.messageList.isEmpty) {
        return state;
      }
      return state.copyWithRemovedMessageAt(state.messageList.length - 1);
    case 'PopFront':
      return state.copyWithRemovedMessageAt(0);
    case 'Clear':
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
        return state.copyWith(
          messageList: before,
          messages: Map.fromEntries(
            state.messages.entries,
          ),
        );
      } else {
        // we have to remove some
        final messages = Map.fromEntries(
          state.messages.entries.where((entry) => !after.contains(entry.key)),
        );
        return state.copyWith(messageList: before, messages: messages);
      }
    default:
      break;
  }
  return state;
}
