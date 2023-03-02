import 'package:effektio/features/home/controllers/home_controller.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart'
    show EffektioSdk;
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
    final sdk = await EffektioSdk.instance;
    try {
      await sdk.login(username, password);
      ref.read(isLoggedInProvider.notifier).update((state) => !state);
      ref.invalidate(clientProvider);
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
    final sdk = await EffektioSdk.instance;
    try {
      await sdk.signUp(username, password, displayName, token);
      ref.read(isLoggedInProvider.notifier).update((state) => !state);
      ref.invalidate(clientProvider);
      state = false;
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      state = false;
    }
  }

  void logOut(BuildContext context) async {
    final sdk = await EffektioSdk.instance;
    await sdk.logout();
    ref.read(isLoggedInProvider.notifier).update((state) => !state);
    Navigator.pushReplacementNamed(context, '/');
    ref.invalidate(clientProvider);
  }
}
