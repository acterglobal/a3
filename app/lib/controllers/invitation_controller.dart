import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class InvitationController extends GetxController {
  List<InvitationEvent> eventList = [];

  InvitationController(Client client) : super() {
    client.getInvitedRooms().then((events) {
      eventList = events.toList();
      client.invitationEventRx()?.listen((event) {
        debugPrint('invited event: ' + event.roomName());
        int index = eventList.indexWhere((x) => x.roomId() == event.roomId());
        if (index == -1) {
          eventList.insert(0, event);
        } else {
          eventList.removeAt(index);
        }
        update(['Chat']);
      });
    });
  }
}
