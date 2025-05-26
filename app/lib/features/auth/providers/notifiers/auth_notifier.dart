import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/router/routes.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::auth::notifier');

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() => false; // loading state

  Future<void> nuke() async {
    await ActerSdk.nuke();
  }

  Future<String?> login(String username, String password) async {
    state = true;
    final sdk = await ref.read(sdkProvider.future);
    try {
      final client = await sdk.login(username, password);
      ref.read(clientProvider.notifier).setClient(client);
      state = false;
      return null;
    } catch (e, s) {
      _log.severe('Login failed', e, s);
      state = false;
      return e.toString();
    }
  }

  Future<void> makeGuest(BuildContext? context) async {
    state = true;
    final sdk = await ref.read(sdkProvider.future);
    try {
      final client = await sdk.newGuestClient(setAsCurrent: true);
      ref.read(clientProvider.notifier).setClient(client);
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
  ) async {
    state = true;
    final sdk = await ref.read(sdkProvider.future);
    try {
      final client = await sdk.register(username, password, displayName, token);
      ref.read(clientProvider.notifier).setClient(client);
      state = false;
      return null;
    } catch (e) {
      state = false;
      rethrow;
    }
  }

  Future<void> logout(BuildContext context) async {
    final sdk = await ref.read(sdkProvider.future);
    final stillHasClient = await sdk.logout();
    if (stillHasClient) {
      _log.info('Still has clients, dropping back to other');
      ref.read(clientProvider.notifier).setClient(sdk.currentClient);
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
