import 'dart:async';

import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:get/get.dart';

// this controller keeps seen_by data by room/user

class ReceiptRoom {
  Map<String, ReceiptUser> users = {};

  void updateUser(String userId, String eventId, int? ts) {
    if (users.containsKey(userId)) {
      users[userId]!.eventId = eventId;
      if (ts != null) {
        users[userId]!.ts = ts;
      }
    } else {
      users[userId] = ReceiptUser(eventId: eventId, ts: ts);
    }
  }
}

class ReceiptUser {
  String eventId;
  int? ts;

  ReceiptUser({
    required this.eventId,
    this.ts,
  });
}

class ReceiptController extends GetxController {
  Client client;
  StreamSubscription<ReceiptEvent>? _eventReceiver;
  final Map<String, ReceiptRoom> _rooms = {};

  ReceiptController({required this.client}) : super();

  @override
  void onInit() {
    super.onInit();

    _eventReceiver = client.receiptEventRx()?.listen((event) {
      String roomId = event.roomId();
      bool changed = false;
      for (var record in event.receiptRecords()) {
        String seenBy = record.seenBy();
        if (seenBy != client.userId().toString()) {
          var room = _getRoom(roomId);
          room.updateUser(seenBy, record.eventId(), record.ts());
          changed = true;
        }
      }
      if (changed) {
        update(['Chat']);
      }
    });
  }

  @override
  void onClose() {
    _eventReceiver?.cancel();

    super.onClose();
  }

  ReceiptRoom _getRoom(String roomId) {
    if (_rooms.containsKey(roomId)) {
      return _rooms[roomId]!;
    }
    ReceiptRoom room = ReceiptRoom();
    _rooms[roomId] = room;
    return room;
  }

  // this will be called via update(['Chat'])
  List<String> getSeenByList(String roomId, int ts) {
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
