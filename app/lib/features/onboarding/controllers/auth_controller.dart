import 'package:effektio/features/home/controllers/home_controller.dart';
import 'package:effektio/features/home/repositories/sdk_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      state = false;
      Navigator.pushReplacementNamed(context, '/');
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
      Navigator.pushReplacementNamed(context, '/');
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
    Navigator.pushReplacementNamed(context, '/');
  }
}
