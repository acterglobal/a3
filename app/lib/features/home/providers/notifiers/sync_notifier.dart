import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

// ignore_for_file: avoid_print
class SyncNotifier extends StateNotifier<bool> {
  late SyncState syncState;
  late Stream<bool>? syncPoller;

  SyncNotifier(Client client) : super(false) {
    startSync(client);
  }

  Future<void> startSync(Client client) async {
    Get.put(ChatRoomController(client: client));
    // Get.put(ReceiptController(client: state!));
    // on release we have a really weird behavior, where, if we schedule
    // any async call in rust too early, they just pend forever. this
    // hack unfortunately means we have two wait a bit but that means
    // we get past the threshold where it is okay to schedule...
    await Future.delayed(const Duration(milliseconds: 1500));
    syncState = client.startSync();
    final syncPoller = syncState.firstSyncedRx();
    syncPoller!.listen((event) {
      if (event) {
        state = true;
      }
    });
  }
}
