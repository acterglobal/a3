// import 'package:acter/features/chat/providers/notifiers/receipt_notifier.dart';
// import 'package:acter/features/chat/models/reciept_room/receipt_room.dart';
import 'dart:async';

import 'package:acter/common/models/profile_data.dart';
// import 'package:acter/common/providers/common_providers.dart';
// import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/models/chat_data_state/chat_data_state.dart';
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
    StateNotifierProvider.autoDispose<ChatListNotifier, ChatDataState>(
  (ref) => ChatListNotifier(
    ref: ref,
    asyncChats: ref.watch(chatStreamProvider),
  ),
);

final chatsSearchProvider = StateProvider<List<Convo>>((ref) => []);

final typingProvider = StateProvider<Map<String, dynamic>>((ref) => {});

// final typingStreamProvider = StreamProvider<TypingEvent>((ref) async* {
//   Map<String, dynamic> typingEvent = {};
//   final client = ref.watch(clientProvider)!;
//   StreamSubscription<TypingEvent>? _subscription;
//   ref.onDispose(() => _subscription!.cancel());
//   final _stream = client.typingEventRx();
//   _subscription = _stream!.listen((event) {
//     debugPrint(
//       'Typing Event : ${event.roomId().toString()}:${event.userIds().toList()}',
//     );
//     final roomId = event.roomId().toString();
//     final List<Convo> roomList = ref.read(chatStreamProvider).requireValue;
//     int idx = roomList.indexWhere((x) {
//       return x.getRoomIdStr() == roomId.toString();
//     });
//     if (idx == -1) {
//       return;
//     }
//     List<types.User> typingUsers = [];
//     for (var userId in event.userIds().toList()) {
//       if (userId == client.userId()) {
//         // filter out my typing
//         continue;
//       }
//       String uid = userId.toString();
//       var user = types.User(
//         id: uid,
//         firstName: simplifyUserId(uid),
//       );
//       typingUsers.add(user);
//     }
//     typingEvent = {
//       'roomId': roomId,
//       'typingUsers': typingUsers,
//     };
//     ref.read(typingProvider.notifier).update((state) => typingEvent);
//   });

//   await for (var e in _stream) {
//     yield e;
//   }
// });

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



// final typingEventProvider =
//     StateNotifierProvider.autoDispose<TypingNotifier, Map<String, dynamic>>(
//         (ref) {
//   final asyncEvent = ref.watch(typingStreamProvider.future);
//   return TypingNotifier(ref: ref, asyncEvent: asyncEvent);
// });

// CHAT Receipt Provider
// final receiptProvider =
//     StateNotifierProvider.autoDispose<ReceiptNotifier, ReceiptRoom?>(
//   (ref) => ReceiptNotifier(ref),
// );
