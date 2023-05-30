import 'package:acter/features/chat/controllers/chat_list_controller.dart';
import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter/features/chat/controllers/receipt_controller.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

final sdkProvider = FutureProvider<ActerSdk>((ref) async {
  return await ActerSdk.instance;
});

final clientProvider = StateNotifierProvider<ClientNotifier, Client?>(
  (ref) => ClientNotifier(ref),
);

class ClientNotifier extends StateNotifier<Client?> {
  late SyncState syncState;
  ClientNotifier(Ref ref) : super(null) {
    _loadUp(ref);
  }

  Future<ActerSdk> _loadUp(Ref ref) async {
    final asyncSdk = await ref.watch(sdkProvider.future);
    PlatformDispatcher.instance.onError = (exception, stackTrace) {
      asyncSdk.writeLog(exception.toString(), 'error');
      asyncSdk.writeLog(stackTrace.toString(), 'error');
      return true; // make this error handled
    };
    state = asyncSdk.currentClient;
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
    return asyncSdk;
  }
}
