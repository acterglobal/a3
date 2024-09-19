import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hasSuperTokensAccess = FutureProvider<bool>((ref) async {
  final asyncVal = ref.watch(superInvitesTokensProvider);
  // if we error’d we assume it is not available on the server.
  return !asyncVal.hasError;
});

final superInvitesTokensProvider =
    FutureProvider<List<SuperInviteToken>>((ref) async {
  final superInvites = ref.watch(superInvitesProvider);
  return (await superInvites.tokens()).toList();
});

final superInviteTokenProvider = FutureProvider.autoDispose
    .family<SuperInviteToken, String>((ref, tokenCode) async {
  final tokens = await ref.watch(superInvitesTokensProvider.future);
  for (final token in tokens) {
    if (token.token() == tokenCode) return token;
  }
  throw 'SuperInvite $tokenCode not found';
});

final superInvitesProvider = Provider<SuperInvites>((ref) {
  final client = ref.watch(alwaysClientProvider);
  return client.superInvites();
});

/// List of SuperInviteTokens that have the given roomId in their to-invite list
final superInvitesForRoom = FutureProvider.autoDispose
    .family<List<SuperInviteToken>, String>((ref, roomId) async {
  final allInvites = await ref.watch(superInvitesTokensProvider.future);
  return allInvites
      .where((invite) => asDartStringList(invite.rooms()).contains(roomId))
      .toList();
});

/// Given the list of rooms this creates a new token with a random key
Future<String> newSuperInviteForRooms(
  WidgetRef ref,
  List<String> rooms, {
  String? inviteCode,
}) async {
  final superInvites = ref.read(superInvitesProvider);
  final builder = superInvites.newTokenUpdater();
  if (inviteCode != null) {
    builder.token(inviteCode);
  }
  for (final roomId in rooms) {
    builder.addRoom(roomId);
  }
  final token = await superInvites.createOrUpdateToken(builder);
  ref.invalidate(superInvitesTokensProvider);
  return token.token();
}

final superInviteInfoProvider = FutureProvider.autoDispose
    .family<SuperInviteInfo, String>((ref, token) async {
  final superInvites = ref.watch(superInvitesProvider);
  return await superInvites.info(token);
});
