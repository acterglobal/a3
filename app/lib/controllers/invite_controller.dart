import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class InviteController extends GetxController {
  static InviteController get instance =>
      Get.put<InviteController>(InviteController());

  List<MembershipEvent> eventList = [];

  void init(Client client) {
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
