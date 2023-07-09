import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/chat/controllers/chat_room_controller.dart';
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

  Future<String?> login(
    String username,
    String password,
  ) async {
    final sdk = await ref.watch(sdkProvider.future);
    try {
      final client = await sdk.login(username, password);
      ref.read(isLoggedInProvider.notifier).update((state) => !state);
      ref.watch(clientProvider.notifier).state = client;
      // inject chat dependencies once actual client is logged in.
      Get.replace(ChatRoomController(client: client));
      // Get.replace(ReceiptController(client: client));
      return null;
    } catch (e) {
      debugPrint('$e');
      return e.toString();
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
        context.goNamed(Routes.main.name);
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
      context.goNamed(Routes.main.name);
    } catch (e) {
      state = false;
    }
  }

  Future<void> logout(BuildContext context) async {
    final sdk = await ref.watch(sdkProvider.future);
    final stillHasClient = await sdk.logout();
    if (stillHasClient) {
      print('Still has clients, dropping back to other');
      ref.read(isLoggedInProvider.notifier).update((state) => true);
      ref.invalidate(clientProvider);
      ref.invalidate(spacesProvider);
      ref.read(clientProvider.notifier).state = sdk.currentClient;
      context.goNamed(Routes.main.name);
    } else {
      print('No clients left, redir to onboarding');
      ref.read(isLoggedInProvider.notifier).update((state) => false);
      ref.invalidate(clientProvider);
      ref.invalidate(spacesProvider);
      context.goNamed(Routes.main.name);
    }
    // return to guest client.
  }
}
