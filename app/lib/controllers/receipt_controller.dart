import 'dart:async';

import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:get/get.dart';

class ReceiptRoom {
  String roomId;
  List<ReceiptUser> users;

  ReceiptRoom({
    required this.roomId,
    required this.users,
  });
}

class ReceiptUser {
  String userId;
  String eventId;
  int? ts;

  ReceiptUser({
    required this.userId,
    required this.eventId,
    this.ts,
  });
}

class ReceiptController extends GetxController {
  Client client;
  String userId;
  StreamSubscription<ReceiptEvent>? _eventSubscription;
  final List<ReceiptRoom> _rooms = [];

  ReceiptController({
    required this.client,
    required this.userId,
  }) : super();

  @override
  void onInit() {
    super.onInit();

    if (!client.isGuest()) {
      _eventSubscription = client.receiptEventRx()!.listen((event) {
        String roomId = event.roomId();
        for (var record in event.receiptRecords()) {
          String seenBy = record.seenBy();
          if (seenBy != userId) {
            var room = _getRoom(roomId);
            _updateUser(room, seenBy, record.eventId(), record.ts());
            update(['Chat']);
          }
        }
      });
    }
  }

  @override
  void onClose() {
    super.onClose();

    if (_eventSubscription != null) {
      _eventSubscription!.cancel();
    }
  }

  ReceiptRoom _getRoom(String roomId) {
    int idx = _rooms.indexWhere((x) => x.roomId == roomId);
    if (idx == -1) {
      ReceiptRoom room = ReceiptRoom(
        roomId: roomId,
        users: [],
      );
      _rooms.add(room);
      return room;
    }
    return _rooms[idx];
  }

  void _updateUser(
    ReceiptRoom room,
    String userId,
    String eventId,
    int? ts,
  ) {
    int idx = room.users.indexWhere((x) => x.userId == userId);
    if (idx == -1) {
      ReceiptUser user = ReceiptUser(
        userId: userId,
        eventId: eventId,
        ts: ts,
      );
      room.users.add(user);
    } else {
      room.users[idx].eventId = eventId;
      if (ts != null) {
        room.users[idx].ts = ts;
      }
    }
  }

  List<String> getSeenByList(String roomId, int ts) {
    List<String> userIds = [];
    int idx = _rooms.indexWhere((x) => x.roomId == roomId);
    if (idx != -1) {
      for (var user in _rooms[idx].users) {
        if (user.ts != null) {
          if (user.ts! >= ts) {
            userIds.add(user.userId);
          }
        }
      }
    }
    return userIds;
  }
}
