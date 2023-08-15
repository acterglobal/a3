import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/onboarding/providers/onboarding_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AuthStateNotifier extends StateNotifier<bool> {
  final Ref ref;

  AuthStateNotifier(this.ref) : super(false);

  Future<String?> login(String username, String password) async {
    var sdk = await ref.read(sdkProvider.future);
    try {
      var client = await sdk.login(username, password);
      ref.read(isLoggedInProvider.notifier).update((state) => !state);
      ref.read(clientProvider.notifier).state = client;
      return null;
    } catch (e) {
      debugPrint('$e');
      return e.toString();
    }
  }

  Future<void> makeGuest(BuildContext? context) async {
    state = true;
    var sdk = await ref.read(sdkProvider.future);
    try {
      var client = await sdk.newGuestClient(setAsCurrent: true);
      ref.read(isLoggedInProvider.notifier).update((state) => !state);
      ref.read(clientProvider.notifier).state = client;
      state = false;
      if (context != null && context.mounted) {
        context.goNamed(Routes.main.name);
      }
    } catch (e) {
      state = false;
    }
  }

  Future<String?> register(
    String username,
    String password,
    String displayName,
    String token,
    BuildContext context,
  ) async {
    var sdk = await ref.read(sdkProvider.future);
    try {
      var client = await sdk.register(username, password, displayName, token);
      ref.read(isLoggedInProvider.notifier).update((state) => !state);
      ref.read(clientProvider.notifier).state = client;

      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (context.mounted) {
        context.goNamed(Routes.main.name);
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout(BuildContext context) async {
    var sdk = await ref.read(sdkProvider.future);
    var stillHasClient = await sdk.logout();
    if (stillHasClient) {
      debugPrint('Still has clients, dropping back to other');
      ref.read(isLoggedInProvider.notifier).update((state) => true);
      ref.invalidate(clientProvider);
      ref.invalidate(spacesProvider);
      ref.read(clientProvider.notifier).state = sdk.currentClient;
      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (context.mounted) {
        context.goNamed(Routes.main.name);
      }
    } else {
      debugPrint('No clients left, redir to onboarding');
      ref.read(isLoggedInProvider.notifier).update((state) => false);
      ref.invalidate(clientProvider);
      ref.invalidate(spacesProvider);

      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (context.mounted) {
        context.goNamed(Routes.main.name);
      }
    }
    // return to guest client.
  }
}
