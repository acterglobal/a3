import 'package:acter/common/providers/notifiers/chat_notifiers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

final convoProvider =
    AsyncNotifierProvider.family<AsyncConvoNotifier, Convo?, Convo>(
  () => AsyncConvoNotifier(),
);

// Chat Providers

final latestMessageProvider =
    StateNotifierProvider.family<LatestMsgNotifier, RoomMessage?, Convo>(
        (ref, convo) {
  return LatestMsgNotifier(ref, convo);
});

/// Provider for fetching rooms list. This'll always bring up unsorted list.
final _convosProvider =
    StateNotifierProvider<ChatRoomsListNotifier, List<Convo>>((ref) {
  final client = ref.watch(alwaysClientProvider);
  return ChatRoomsListNotifier(ref: ref, client: client);
});

/// Provider that sorts up list based on latest timestamp from [_convosProvider].
final chatsProvider = StateProvider<List<Convo>>((ref) {
  final convos = ref.watch(_convosProvider);
  convos.sort((a, b) => b.latestMessageTs().compareTo(a.latestMessageTs()));
  return convos;
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

final relatedChatsProvider =
    FutureProvider.family<List<Convo>, String>((ref, spaceId) async {
  final chats =
      (await ref.watch(spaceRelationsOverviewProvider(spaceId).future))
          .knownChats;
  chats.sort((a, b) => b.latestMessageTs().compareTo(a.latestMessageTs()));
  return chats;
});

final selectedChatIdProvider =
    NotifierProvider<SelectedChatIdNotifier, String?>(
  () => SelectedChatIdNotifier(),
);
