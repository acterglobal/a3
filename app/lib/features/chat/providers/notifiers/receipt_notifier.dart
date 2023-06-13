import 'dart:async';

import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter/features/chat/models/receipt_user.dart';
import 'package:acter/features/chat/models/reciept_room/receipt_room.dart';
import 'package:acter/features/chat/providers/notifiers/chat_messages_notifier.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class ReceiptNotifier extends StateNotifier<ReceiptRoom?> {
  final Ref ref;
  final Map<RoomId, ReceiptRoom> _rooms = {};
  ReceiptNotifier(this.ref) : super(null) {
    _init();
  }

  void _init() {
    final client = ref.read(clientProvider);
    state = const ReceiptRoom(users: {});
    StreamSubscription<ReceiptEvent>? _subscription;
    _subscription = client?.receiptEventRx()?.listen((event) {
      String myId = client.userId().toString();
      RoomId roomId = event.roomId();
      for (var record in event.receiptRecords()) {
        String seenBy = record.seenBy();
        if (seenBy != myId) {
          var room = _getRoom(roomId);
          state = room;
          updateUser(seenBy, record.eventId(), record.ts());
        }
      }
    });

    ref.onDispose(() {
      _subscription!.cancel();
    });
  }

  void updateUser(String userId, String eventId, int? ts) {
    final Map<String, ReceiptUser> receiptUsers = state!.users;
    if (receiptUsers.containsKey(userId)) {
      receiptUsers[userId]!.eventId = eventId;
      if (ts != null) {
        receiptUsers[userId]!.ts = ts;
      }
    } else {
      receiptUsers[userId] =
          ReceiptUser(userId: userId, eventId: eventId, ts: ts);
    }
    state = state!.copyWith(users: receiptUsers);
  }

  ReceiptRoom _getRoom(RoomId roomId) {
    if (state!.users.containsKey(roomId)) {
      return _rooms[roomId]!;
    }
    var room = const ReceiptRoom();
    _rooms[roomId] = room;
    debugPrint('$_rooms');
    return room;
  }

  void loadRoom(Conversation conversation, List<ReceiptRecord> records) {
    var room = _getRoom(conversation.getRoomId());
    state = room;
    for (var record in records) {
      String seenBy = record.seenBy();
      updateUser(seenBy, record.eventId(), record.ts());
    }
  }

  // this will be called via update(['Chat'])
  List<String> getSeenByList(RoomId roomId, int ts) {
    List<String> userIds = [];
    if (_rooms.containsKey(roomId)) {
      _rooms[roomId]!.users.forEach((userId, user) {
        if (user.ts != null) {
          if (user.ts! >= ts) {
            userIds.add(userId);
          }
        }
      });
    }
    return userIds;
  }
}
