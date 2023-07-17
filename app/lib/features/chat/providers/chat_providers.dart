// import 'package:acter/features/chat/providers/notifiers/receipt_notifier.dart';
// import 'package:acter/features/chat/models/reciept_room/receipt_room.dart';
import 'dart:async';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/models/chat_data_state/chat_data_state.dart';
import 'package:acter/features/chat/providers/notifiers/chat_notifiers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Convo, TypingEvent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

// chats stream provider
final chatStreamProvider =
    StreamProvider.autoDispose<List<Convo>>((ref) async* {
  final client = ref.watch(clientProvider)!;
  StreamSubscription<List<Convo>>? _subscription;
  ref.onDispose(() => _subscription!.cancel());
  final _stream =
      client.convosRx().asBroadcastStream().map((event) => event.toList());
  _subscription = _stream.listen((event) {
    debugPrint('Acter Conversations Stream');
  });
  await for (List<Convo> event in _stream) {
    // make sure we aren't emitting empty list
    if (event.isNotEmpty) {
      ///FIXME: for no rooms, this might leads to loading infinitely.
      event.sort((a, b) {
        if (a.latestMessage() == null) {
          return 1;
        }
        if (b.latestMessage() == null) {
          return -1;
        } else {
          return b
              .latestMessage()!
              .eventItem()!
              .originServerTs()
              .compareTo(a.latestMessage()!.eventItem()!.originServerTs());
        }
      });
      yield event;
    }
  }
});

// CHAT PAGE state provider
final chatsProvider =
    StateNotifierProvider.autoDispose<ChatsNotifier, ChatDataState>((ref) {
  final asyncChats = ref.watch(chatStreamProvider);
  return ChatsNotifier(ref: ref, asyncChats: asyncChats);
});

final chatsSearchProvider = StateProvider<List<Convo>>((ref) => []);

final typingProvider = StateProvider<Map<String, dynamic>>((ref) => {});

final typingStreamProvider = StreamProvider<TypingEvent>((ref) async* {
  Map<String, dynamic> typingEvent = {};
  final client = ref.watch(clientProvider)!;
  StreamSubscription<TypingEvent>? _subscription;
  ref.onDispose(() => _subscription!.cancel());
  final _stream = client.typingEventRx();
  _subscription = _stream!.listen((event) {
    debugPrint(
      'Typing Event : ${event.roomId().toString()}:${event.userIds().toList()}',
    );
    final roomId = event.roomId().toString();
    final List<Convo> roomList = ref.read(chatStreamProvider).requireValue;
    int idx = roomList.indexWhere((x) {
      return x.getRoomIdStr() == roomId.toString();
    });
    if (idx == -1) {
      return;
    }
    List<types.User> typingUsers = [];
    for (var userId in event.userIds().toList()) {
      if (userId == client.userId()) {
        // filter out my typing
        continue;
      }
      String uid = userId.toString();
      var user = types.User(
        id: uid,
        firstName: simplifyUserId(uid),
      );
      typingUsers.add(user);
    }
    typingEvent = {
      'roomId': roomId,
      'typingUsers': typingUsers,
    };
    ref.read(typingProvider.notifier).update((state) => typingEvent);
  });

  await for (var e in _stream) {
    yield e;
  }
});

// final typingEventProvider =
//     StateNotifierProvider.autoDispose<TypingNotifier, Map<String, dynamic>>(
//         (ref) {
//   final asyncEvent = ref.watch(typingStreamProvider.future);
//   return TypingNotifier(ref: ref, asyncEvent: asyncEvent);
// });
// // Conversations List Provider (CHAT PAGE)
// final joinedRoomListProvider =
//     StateNotifierProvider.autoDispose<JoinedRoomNotifier, List<JoinedRoom>>(
//   (ref) => JoinedRoomNotifier(),
// );

// CHAT Receipt Provider
// final receiptProvider =
//     StateNotifierProvider.autoDispose<ReceiptNotifier, ReceiptRoom?>(
//   (ref) => ReceiptNotifier(ref),
// );
