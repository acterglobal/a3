import 'dart:async';

import 'package:acter/common/models/profile_data.dart';
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

// chats stream provider
final chatStreamProvider =
    StreamProvider.autoDispose<List<Convo>>((ref) async* {
  final client = ref.watch(clientProvider)!;
  StreamSubscription<FfiListConvo>? subscription;
  List<Convo> conversations = [];
  subscription = client.convosRx().listen((event) {
    conversations.addAll(event.toList());
    debugPrint('Acter Conversations Stream');
  });
  ref.onDispose(() async {
    debugPrint('disposing conversation stream');
    await subscription?.cancel();
  });
  yield conversations;
});

// CHAT PAGE state provider
final chatListProvider =
    StateNotifierProvider.autoDispose<ChatListNotifier, ChatListState>(
  (ref) => ChatListNotifier(
    ref: ref,
    asyncChats: ref.watch(chatStreamProvider),
  ),
);

final chatsSearchProvider = StateProvider<List<Convo>>((ref) => []);

final typingProvider = StateProvider<Map<String, dynamic>>((ref) => {});

final chatRoomProvider =
    StateNotifierProvider.autoDispose<ChatRoomNotifier, ChatRoomState>((ref) {
  return ChatRoomNotifier(
    ref: ref,
  );
});

final messagesProvider =
    StateNotifierProvider.autoDispose<MessagesNotifier, List<types.Message>>(
  (ref) => MessagesNotifier(),
);

final chatInputProvider =
    StateNotifierProvider<ChatInputNotifier, ChatInputState>(
  (ref) => ChatInputNotifier(),
);

// chat room member profiles
final chatProfilesProvider =
    StateProvider<Map<String, ProfileData>>((ref) => {});

// chat room mention list
final mentionListProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

// emoji row preview toggler
final toggleEmojiRowProvider = StateProvider<bool>((ref) => false);

final messageMarkDownProvider = StateProvider<Map<String, String>>((ref) => {});

final mentionKeyProvider = StateProvider<GlobalKey<FlutterMentionsState>>(
  (ref) => GlobalKey<FlutterMentionsState>(),
);

final chatInputFocusProvider = StateProvider<FocusNode>((ref) => FocusNode());
