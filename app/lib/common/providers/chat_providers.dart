import 'package:acter/common/providers/notifiers/chat_notifiers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/search/providers/quick_search_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

final chatProvider =
    AsyncNotifierProvider.family<AsyncConvoNotifier, Convo?, String>(
  () => AsyncConvoNotifier(),
);

// Chat Providers

final latestMessageProvider =
    AsyncNotifierProvider.family<AsyncLatestMsgNotifier, RoomMessage?, String>(
  () => AsyncLatestMsgNotifier(),
);

/// Provider for fetching rooms list. This’ll always bring up unsorted list.
final _convosProvider = NotifierProvider<ChatRoomsListNotifier, List<Convo>>(
  () => ChatRoomsListNotifier(),
);

/// Provider that sorts up list based on latest timestamp from [_convosProvider].
final chatsProvider = Provider<List<Convo>>((ref) {
  final convos = List.of(ref.watch(_convosProvider));
  convos.sort((a, b) => b.latestMessageTs().compareTo(a.latestMessageTs()));
  return convos;
});

final chatIdsProvider = Provider<List<String>>(
  (ref) => ref.watch(chatsProvider).map((e) => e.getRoomIdStr()).toList(),
);

final selectedChatIdProvider =
    NotifierProvider<SelectedChatIdNotifier, String?>(
  () => SelectedChatIdNotifier(),
);

final chatComposerDraftProvider = FutureProvider.autoDispose
    .family<ComposeDraft?, String>((ref, roomId) async {
  final chat = await ref.watch(chatProvider(roomId).future);
  if (chat == null) {
    return null;
  }
  return (await chat.msgDraft().then((val) => val.draft()));
});

//Space list for quick search value provider
final chatListQuickSearchedProvider = Provider.autoDispose<List<Convo>>((ref) {
  final chatsList = ref.watch(chatsProvider);
  final searchTerm = ref.watch(quickSearchValueProvider).trim().toLowerCase();

  //Return all chats if search is empty
  final searchValue = searchTerm.trim().toLowerCase();
  if (searchValue.isEmpty) return chatsList;
  return _filterByTerm(ref, chatsList, searchValue);
});

List<Convo> _filterByTerm(Ref ref, List<Convo> chatList, String searchValue) =>
    chatList.where((convo) {
      final roomId = convo.getRoomIdStr();
      final roomInfo = ref.watch(roomAvatarInfoProvider(roomId));
      final chatName = roomInfo.displayName ?? roomId;
      return chatName.toLowerCase().contains(searchValue);
    }).toList();
