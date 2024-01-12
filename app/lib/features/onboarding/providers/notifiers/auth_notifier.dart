import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AuthStateNotifier extends StateNotifier<bool> {
  final Ref ref;

  AuthStateNotifier(this.ref) : super(false);

  Future<void> nuke(BuildContext context) async {
    await ActerSdk.nuke();
    ref.invalidate(spacesProvider);

    // We are doing as expected, but the lints triggers.
    // ignore: use_build_context_synchronously
    if (context.mounted) {
      context.goNamed(Routes.main.name);
    }
  }

  Future<String?> login(String username, String password) async {
    state = true;
    final sdk = await ref.read(sdkProvider.future);
    try {
      final client = await sdk.login(username, password);
      ref.read(clientProvider.notifier).state = client;
      state = false;
      return null;
    } catch (e) {
      state = false;
      debugPrint('$e');
      return e.toString();
    }
  }

  Future<void> makeGuest(BuildContext? context) async {
    state = true;
    final sdk = await ref.read(sdkProvider.future);
    try {
      final client = await sdk.newGuestClient(setAsCurrent: true);
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
    state = true;
    final sdk = await ref.read(sdkProvider.future);
    try {
      final client = await sdk.register(username, password, displayName, token);
      ref.read(clientProvider.notifier).state = client;
      state = false;
      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (context.mounted) {
        context.goNamed(Routes.main.name);
      }
      return null;
    } catch (e) {
      state = false;
      return e.toString();
    }
  }

  Future<void> logout(BuildContext context) async {
    final sdk = await ref.read(sdkProvider.future);
    final stillHasClient = await sdk.logout();
    if (stillHasClient) {
      debugPrint('Still has clients, dropping back to other');
      ref.read(clientProvider.notifier).state = sdk.currentClient;
      ref.invalidate(spacesProvider);
      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (context.mounted) {
        context.goNamed(Routes.main.name);
      }
    } else {
      debugPrint('No clients left, redir to onboarding');
      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (context.mounted) {
        context.goNamed(Routes.main.name);
      }
    }
  }
}
