import 'dart:async';
import 'package:acter/features/chat/models/chat_list_state/chat_list_state.dart';
import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:acter/features/chat/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat/providers/notifiers/chat_input_notifier.dart';
import 'package:acter/features/chat/providers/notifiers/chat_list_notifier.dart';
import 'package:acter/features/chat/providers/notifiers/chat_room_notifier.dart';
import 'package:acter/features/chat/providers/notifiers/messages_notifier.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Convo, FfiListConvo;
import 'package:flutter/material.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:jiffy/jiffy.dart';

// chats stream provider
final chatStreamProvider = StreamProvider<List<Convo>>((ref) async* {
  final client = ref.watch(clientProvider)!;
  StreamSubscription<FfiListConvo>? subscription;
  StreamController<List<Convo>> controller = StreamController<List<Convo>>();
  subscription = client.convosRx().listen((event) {
    controller.add(event.toList());
    debugPrint('Acter Conversations Stream');
  });
  await for (var convoList in controller.stream) {
    convoList.retainWhere((room) => room.isJoined());
    List<Map<String, dynamic>> sortedConversations =
        convoList.map((conversation) {
      final time = Jiffy.parseFromMillisecondsSinceEpoch(
        conversation.latestMessage()!.eventItem()!.originServerTs(),
      );
      return {'time': time, 'conversation': conversation};
    }).toList()
          ..sort(
            (a, b) => (b['time'] as Jiffy).isAfter(a['time'] as Jiffy) ? -1 : 1,
          );

    final conversations = sortedConversations.reversed
        .map((item) => (item['conversation']) as Convo)
        .toList();
    //FIXME: how to check empty chats ?
    if (conversations.isNotEmpty) {
      yield conversations;
    }
  }
  ref.onDispose(() async {
    debugPrint('disposing conversation stream');
    await subscription?.cancel();
  });
});

// CHAT PAGE state provider
final chatListProvider = StateNotifierProvider<ChatListNotifier, ChatListState>(
  (ref) => ChatListNotifier(
    ref: ref,
    asyncChats: ref.watch(chatStreamProvider),
  ),
);

final chatsSearchProvider = StateProvider<List<Convo>>((ref) => []);

final typingProvider = StateProvider<Map<String, dynamic>>((ref) => {});

final chatRoomProvider =
    StateNotifierProvider<ChatRoomNotifier, ChatRoomState>((ref) {
  return ChatRoomNotifier(
    ref: ref,
  );
});

final messagesProvider =
    StateNotifierProvider<MessagesNotifier, List<types.Message>>(
  (ref) => MessagesNotifier(),
);

final chatInputProvider =
    StateNotifierProvider<ChatInputNotifier, ChatInputState>(
  (ref) => ChatInputNotifier(),
);

// chat room mention list
final mentionListProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

final messageMarkDownProvider = StateProvider<Map<String, String>>((ref) => {});

final mentionKeyProvider = StateProvider<GlobalKey<FlutterMentionsState>>(
  (ref) => GlobalKey<FlutterMentionsState>(),
);

final chatInputFocusProvider = StateProvider<FocusNode>((ref) => FocusNode());

final currentConvoProvider = StateProvider<Convo?>((ref) => null);

final paginationProvider = StateProvider.autoDispose<bool>((ref) => true);

// for desktop only
final showFullSplitView = StateProvider<bool>((ref) => false);
