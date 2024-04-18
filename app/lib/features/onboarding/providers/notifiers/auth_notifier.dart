import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::onboarding::auth');

class AuthStateNotifier extends StateNotifier<bool> {
  final Ref ref;

  AuthStateNotifier(this.ref) : super(false);

  Future<void> nuke(BuildContext context) async {
    await ActerSdk.nuke();
    ref.invalidate(spacesProvider);

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
    } catch (e, s) {
      state = false;
      _log.severe('Login failed', e, s);
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
      _log.info('Still has clients, dropping back to other');
      ref.read(clientProvider.notifier).state = sdk.currentClient;
      ref.invalidate(spacesProvider);
      if (context.mounted) {
        context.goNamed(Routes.main.name);
      }
    } else {
      _log.warning('No clients left, redir to onboarding');
      if (context.mounted) {
        context.goNamed(Routes.main.name);
      }
    }
  }
}
