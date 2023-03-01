import 'package:effektio/features/chat/controllers/chat_list_controller.dart';
import 'package:effektio/features/chat/controllers/chat_room_controller.dart';
import 'package:effektio/features/chat/controllers/receipt_controller.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart'
    show Client, EffektioSdk;
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

final clientProvider =
    StateNotifierProvider<ClientStateNotifier, AsyncValue<Client>>(
  (ref) => ClientStateNotifier(),
);

class ClientStateNotifier extends StateNotifier<AsyncValue<Client>> {
  ClientStateNotifier() : super(const AsyncLoading()) {
    getClient();
  }

  Future<void> getClient() async {
    state = const AsyncLoading();
    final sdk = await EffektioSdk.instance;
    state = await AsyncValue.guard(() async {
      final client = await sdk.currentClient;
      client.startSync();
      Get.put(ChatListController(client: client));
      Get.put(ChatRoomController(client: client));
      Get.put(ReceiptController(client: client));
      return client;
    });
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile>>(
  (ref) => UserProfileNotifier(ref),
);

class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile>> {
  final Ref ref;
  UserProfileNotifier(this.ref) : super(const AsyncLoading()) {
    getUser();
  }

  Future<void> getUser() async {
    state = const AsyncLoading();
    final client = ref.read(clientProvider).requireValue;
    state = await AsyncValue.guard(() async {
      final userProfile = await client.getUserProfile();
      return userProfile;
    });
  }
}
