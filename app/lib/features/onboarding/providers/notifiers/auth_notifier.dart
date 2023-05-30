import 'package:acter/features/chat/controllers/chat_list_controller.dart';
import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter/features/chat/controllers/receipt_controller.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/onboarding/providers/onboarding_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class AuthStateNotifier extends StateNotifier<bool> {
  final Ref ref;
  AuthStateNotifier(this.ref) : super(false);

  Future<void> login(
    String username,
    String password,
    BuildContext context,
  ) async {
    state = true;
    final sdk = await ref.watch(sdkProvider.future);
    try {
      final client = await sdk.login(username, password);
      ref.read(isLoggedInProvider.notifier).update((state) => !state);
      ref.read(clientProvider.notifier).state = client;
      ref.read(clientProvider.notifier).syncState = client.startSync();
      // inject chat dependencies once actual client is logged in.
      Get.replace(ChatListController(client: client));
      Get.replace(ChatRoomController(client: client));
      Get.replace(ReceiptController(client: client));
      state = false;
      context.go(Routes.main.name);
    } catch (e) {
      debugPrint('$e');
      state = false;
    }
  }

  Future<void> makeGuest(
    BuildContext? context,
  ) async {
    state = true;
    final sdk = await ref.watch(sdkProvider.future);
    try {
      final client = await sdk.newGuestClient(setAsCurrent: true);
      ref.read(isLoggedInProvider.notifier).update((state) => !state);
      ref.read(clientProvider.notifier).state = client;
      state = false;
      if (context != null) {
        context.go(Routes.main.name);
      }
    } catch (e) {
      state = false;
    }
  }

  Future<void> register(
    String username,
    String password,
    String displayName,
    String token,
    BuildContext context,
  ) async {
    state = true;
    final sdk = await ref.watch(sdkProvider.future);
    try {
      final client = await sdk.register(username, password, displayName, token);
      ref.read(isLoggedInProvider.notifier).update((state) => !state);
      ref.read(clientProvider.notifier).state = client;
      state = false;
      context.go(Routes.main.name);
    } catch (e) {
      state = false;
    }
  }

  void logout(BuildContext context) async {
    final sdk = await ref.watch(sdkProvider.future);
    await sdk.logout();
    ref.read(isLoggedInProvider.notifier).update((state) => !state);
    // return to guest client.
    ref.read(clientProvider.notifier).state = sdk.currentClient;
    Get.delete<ChatListController>();
    Get.delete<ChatRoomController>();
    Get.delete<ReceiptController>();
    context.go(Routes.main.name);
  }
}
