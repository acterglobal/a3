import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/notifiers/chat_notifiers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::common::chat');

/// Provider the profile data of a the given space, keeps up to date with underlying client
final convoProvider =
    AsyncNotifierProvider.family<AsyncConvoNotifier, Convo?, Convo>(
  () => AsyncConvoNotifier(),
);

// Chat Providers
final chatProfileDataProvider =
    FutureProvider.family<ProfileData, Convo>((ref, convo) async {
  // this ensure we are staying up to dates on updates to convo
  final chat = await ref.watch(convoProvider(convo).future);
  if (chat == null) {
    throw 'Chat not accessible';
  }
  final profile = chat.getProfile();
  final displayName = await profile.getDisplayName();
  final isDm = chat.isDm();
  try {
    if (profile.hasAvatar()) {
      final sdk = await ref.watch(sdkProvider.future);
      final size = sdk.api.newThumbSize(48, 48);
      final avatar = await profile.getAvatar(size);
      return ProfileData(displayName.text(), avatar.data(), isDm: isDm);
    }
  } catch (e, s) {
    _log.severe('Loading avatar for ${convo.getRoomIdStr()} failed', e, s);
  }
  return ProfileData(displayName.text(), null, isDm: isDm);
});

final latestMessageProvider =
    StateNotifierProvider.family<LatestMsgNotifier, RoomMessage?, Convo>(
        (ref, convo) {
  return LatestMsgNotifier(ref, convo);
});

final chatProfileDataProviderById =
    FutureProvider.family<ProfileData, String>((ref, roomId) async {
  final chat = await ref.watch(chatProvider(roomId).future);
  return await ref.watch(chatProfileDataProvider(chat).future);
});

/// Provider the profile data of a the given space, keeps up to date with underlying client
final chatsProvider =
    StateNotifierProvider<ChatRoomsListNotifier, List<Convo>>((ref) {
  final client = ref.watch(alwaysClientProvider);
  return ChatRoomsListNotifier(ref: ref, client: client);
});

final chatProvider =
    FutureProvider.family<Convo, String>((ref, roomIdOrAlias) async {
  final client = ref.watch(alwaysClientProvider);
  // FIXME: fallback to fetching a public data, if not found
  return await client.convoWithRetry(
    roomIdOrAlias,
    120,
  ); // retrying for up to 30seconds before failing
});

final relatedChatsProvider = FutureProvider.autoDispose
    .family<List<Convo>, String>((ref, spaceId) async {
  return (await ref.watch(spaceRelationsOverviewProvider(spaceId).future))
      .knownChats;
});

final selectedChatIdProvider =
    NotifierProvider<SelectedChatIdNotifier, String?>(
  () => SelectedChatIdNotifier(),
);
