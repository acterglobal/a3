import 'package:acter/features/chat/controllers/chat_list_controller.dart';
import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter/features/chat/controllers/receipt_controller.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

final clientProvider = StateNotifierProvider<ClientNotifier, Client?>(
  (ref) => ClientNotifier(ref),
);

class ClientNotifier extends StateNotifier<Client?> {
  final Ref ref;
  late ActerSdk sdk;
  late SyncState syncState;
  ClientNotifier(this.ref) : super(null) {
    _loadUp();
  }

  void _loadUp() async {
    final asyncSdk = await ActerSdk.instance;
    PlatformDispatcher.instance.onError = (exception, stackTrace) {
      asyncSdk.writeLog(exception.toString(), 'error');
      asyncSdk.writeLog(stackTrace.toString(), 'error');
      return true; // make this error handled
    };
    sdk = asyncSdk;
    state = sdk.currentClient;
    if (state != null || !state!.isGuest()) {
      Get.put(ChatListController(client: state!));
      Get.put(ChatRoomController(client: state!));
      Get.put(ReceiptController(client: state!));
      // on release we have a really weird behavior, where, if we schedule
      // any async call in rust too early, they just pend forever. this
      // hack unfortunately means we have two wait a bit but that means
      // we get past the threshold where it is okay to schedule...
      await Future.delayed(const Duration(milliseconds: 1500));
      syncState = state!.startSync();
    }
  }
}
