import 'package:effektio/features/home/controllers/home_controller.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Client, UserProfile, News;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clientRepositoryProvider = StateProvider<ClientRepository>((ref) {
  final client = ref.watch(homeStateProvider.notifier).client;
  return ClientRepository(client: client);
});

class ClientRepository {
  final Client client;

  ClientRepository({required this.client});

  bool isGuest() => client.isGuest();
  String userId() => client.userId().toString();

  Future<UserProfile> userProfile() async {
    final userProfile = await client.getUserProfile();
    return userProfile;
  }

  Future<List<News>> news() async {
    final newsList =
        await client.latestNews().then((ffiList) => ffiList.toList());
    return newsList;
  }
}
