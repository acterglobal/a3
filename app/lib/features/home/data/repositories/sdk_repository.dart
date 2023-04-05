import 'package:acter/common/controllers/client_controller.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart' show ActerSdk, Client;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sdkRepositoryProvider = Provider<SdkRepository>((ref) {
  final sdk = ref.watch(clientProvider.notifier).sdk;
  return SdkRepository(sdk);
});

class SdkRepository {
  final ActerSdk sdk;

  SdkRepository(this.sdk);

  Client getClient() => sdk.currentClient;

  Future<Client> loginClient(String username, String password) async {
    try {
      final client = await sdk.login(username, password);
      return client;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logoutClient() async {
    try {
      await sdk.logout();
    } catch (e) {
      rethrow;
    }
  }

  Future<Client> signUpClient(
    String name,
    String username,
    String password,
    String token,
  ) async {
    try {
      final client = await sdk.signUp(username, password, name, token);
      return client;
    } catch (e) {
      rethrow;
    }
  }

  void setSpaceSettings(String name) async {
    try {
      sdk.newSpaceSettings(name);
    } catch (e) {
      rethrow;
    }
  }
}
