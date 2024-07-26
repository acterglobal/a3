import 'package:acter/common/providers/notifiers/chat_notifiers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

final convoProvider =
    AsyncNotifierProvider.family<AsyncConvoNotifier, Convo?, String>(
  () => AsyncConvoNotifier(),
);

// Chat Providers

final latestMessageProvider =
    AsyncNotifierProvider.family<AsyncLatestMsgNotifier, RoomMessage?, String>(
  () => AsyncLatestMsgNotifier(),
);

/// Provider for fetching rooms list. This'll always bring up unsorted list.
final _convosProvider =
    StateNotifierProvider<ChatRoomsListNotifier, List<Convo>>((ref) {
  final client = ref.watch(alwaysClientProvider);
  return ChatRoomsListNotifier(ref: ref, client: client);
});

/// Provider that sorts up list based on latest timestamp from [_convosProvider].
final chatsProvider = Provider<List<Convo>>((ref) {
  final convos = List.of(ref.watch(_convosProvider));
  convos.sort((a, b) => b.latestMessageTs().compareTo(a.latestMessageTs()));
  return convos;
});

final chatIdsProvider = Provider<List<String>>(
    (ref) => ref.watch(chatsProvider).map((e) => e.getRoomIdStr()).toList(),);

final chatProvider =
    FutureProvider.family<Convo, String>((ref, roomIdOrAlias) async {
  final client = ref.watch(alwaysClientProvider);
  // FIXME: fallback to fetching a public data, if not found
  return await client.convoWithRetry(
    roomIdOrAlias,
    120,
  ); // retrying for up to 30seconds before failing
});

final selectedChatIdProvider =
    NotifierProvider<SelectedChatIdNotifier, String?>(
  () => SelectedChatIdNotifier(),
);
