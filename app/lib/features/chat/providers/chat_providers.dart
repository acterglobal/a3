import 'dart:async';
import 'package:acter/common/providers/common_providers.dart';
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

List<Convo> filterConvos(List<Convo> convoList) {
  convoList.retainWhere((room) => room.isJoined());
  convoList.sort(
    (a, b) => Jiffy.parseFromMillisecondsSinceEpoch(b.latestMessageTs())
            .isAfter(Jiffy.parseFromMillisecondsSinceEpoch(a.latestMessageTs()))
        ? 1
        : -1,
  );

  return convoList;
}

// chats stream provider
final chatStreamProvider = StreamProvider<List<Convo>>((ref) async* {
  final client = ref.watch(clientProvider)!;
  final convoList = filterConvos((await client.convos()).toList());
  if (convoList.isNotEmpty) {
    yield convoList;
  }
  StreamSubscription<FfiListConvo>? subscription;
  StreamController<List<Convo>> controller = StreamController<List<Convo>>();
  subscription = client.convosRx().listen((event) {
    controller.add(event.toList());
    debugPrint('Acter Conversations Stream');
  });
  await for (final convoList in controller.stream) {
    final conversations = filterConvos(convoList);
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

final selectedChatIdProvider = StateProvider<String?>((ref) => null);

final chatInputFocusProvider = StateProvider<FocusNode>((ref) => FocusNode());

final paginationProvider = StateProvider.autoDispose<bool>((ref) => true);

// for desktop only
final showFullSplitView = StateProvider<bool>((ref) => false);
