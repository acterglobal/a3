import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class InviteController extends GetxController {
  List<MembershipEvent> eventList = [];

  InviteController(Client client) : super() {
    client.membershipEventRx()!.listen((event) {
      debugPrint('invited event: ' + event.getRoomName());
      int index =
          eventList.indexWhere((el) => el.getRoomId() == event.getRoomId());
      if (index == -1) {
        eventList.add(event);
      } else {
        eventList.removeAt(index);
      }
      update(['Chat']);
    });
  }
}
