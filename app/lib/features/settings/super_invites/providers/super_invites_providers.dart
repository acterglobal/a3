import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

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
