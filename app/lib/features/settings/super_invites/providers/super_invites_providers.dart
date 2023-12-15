import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ignoredUsersProvider = FutureProvider<List<UserId>>((ref) async {
  final account = await ref.watch(accountProvider.future);
  return (await account.ignoredUsers()).toList();
});

final hasSuperTokensAccess = FutureProvider<bool>((ref) async {
  final asyncVal = ref.watch(superInvitesTokensProvider);
  return !asyncVal
      .hasError; // if we error'd we assume it is not available on the server.
});

final superInvitesTokensProvider =
    FutureProvider<List<SuperInviteToken>>((ref) async {
  final superInvites = ref.watch(superInvitesProvider);
  return (await superInvites.tokens()).toList();
});

final superInvitesProvider = Provider<SuperInvites>((ref) {
  final client = ref.watch(alwaysClientProvider);
  return client.superInvites();
});
