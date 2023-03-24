import 'package:acter/features/chat/controllers/chat_list_controller.dart';
import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter/features/chat/controllers/receipt_controller.dart';
import 'package:acter/features/home/controllers/home_controller.dart';
import 'package:acter/features/home/data/repositories/sdk_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, bool>((ref) => AuthController(ref));

final isLoggedInProvider = StateProvider<bool>((ref) => false);

class AuthController extends StateNotifier<bool> {
  final Ref ref;
  AuthController(this.ref) : super(false);

  Future<void> login(
    String username,
    String password,
    BuildContext context,
  ) async {
    state = true;
    final sdk = ref.read(sdkRepositoryProvider);
    try {
      final client = await sdk.loginClient(username, password);
      ref.read(isLoggedInProvider.notifier).update((state) => !state);
      ref.read(homeStateProvider.notifier).state = client;
      ref.read(homeStateProvider.notifier).syncState = client.startSync();
      // inject chat dependencies once actual client is logged in.
      Get.replace(ChatListController(client: client));
      Get.replace(ChatRoomController(client: client));
      Get.replace(ReceiptController(client: client));
      state = false;
      context.go('/');
    } catch (e) {
      debugPrint('$e');
      state = false;
    }
  }

  Future<void> signUp(
    String username,
    String password,
    String displayName,
    String token,
    BuildContext context,
  ) async {
    state = true;
    final sdk = ref.read(sdkRepositoryProvider);
    try {
      final client =
          await sdk.signUpClient(username, password, displayName, token);
      ref.read(isLoggedInProvider.notifier).update((state) => !state);
      ref.read(homeStateProvider.notifier).state = client;
      state = false;
      context.go('/');
    } catch (e) {
      state = false;
    }
  }

  void logOut(BuildContext context) async {
    final sdk = ref.read(sdkRepositoryProvider);
    await sdk.logoutClient();
    ref.read(isLoggedInProvider.notifier).update((state) => !state);
    // return to guest client.
    ref.read(homeStateProvider.notifier).state = sdk.getClient();
    Get.delete<ChatListController>();
    Get.delete<ChatRoomController>();
    Get.delete<ReceiptController>();
    context.go('/');
  }
}
