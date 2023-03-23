import 'package:acter/features/chat/controllers/chat_list_controller.dart';
import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter/features/chat/controllers/receipt_controller.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

final homeStateProvider = StateNotifierProvider<HomeStateNotifier, Client?>(
  (ref) => HomeStateNotifier(ref),
);

// final initialSyncedProvider = FutureProvider((ref) async {
//   final homeState = ref.watch(homeStateProvider);
//   await for (final value in homeState.syncState.firstSyncedRx()) {
//     if (value) {
//       return true;
//     }
//   }
//   return false;
// });

class HomeStateNotifier extends StateNotifier<Client?> {
  final Ref ref;
  late ActerSdk sdk;
  late SyncState syncState;
  HomeStateNotifier(this.ref) : super(null) {
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
      syncState = state!.startSync();
    }
  }
}
