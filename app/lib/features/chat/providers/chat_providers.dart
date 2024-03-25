import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:acter/features/chat/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat/models/media_chat_state/media_chat_state.dart';
import 'package:acter/features/chat/models/room_list_filter_state/room_list_filter_state.dart';
import 'package:acter/features/chat/providers/notifiers/chat_input_notifier.dart';
import 'package:acter/features/chat/providers/notifiers/chat_room_notifier.dart';
import 'package:acter/features/chat/providers/notifiers/media_chat_notifier.dart';
import 'package:acter/features/chat/providers/room_list_filter_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

final chatInputProvider =
    StateNotifierProvider.family<ChatInputNotifier, ChatInputState, String>(
  (ref, roomId) => ChatInputNotifier(),
);

final chatInputFocusProvider = StateProvider<FocusNode>((ref) => FocusNode());
final chatStateProvider =
    StateNotifierProvider.family<ChatRoomNotifier, ChatRoomState, Convo>(
  (ref, convo) => ChatRoomNotifier(ref: ref, convo: convo),
);

final mediaChatStateProvider = StateNotifierProvider.family<MediaChatNotifier,
    MediaChatState, ChatMessageInfo>(
  (ref, messageInfo) => MediaChatNotifier(ref: ref, messageInfo: messageInfo),
);

final filteredChatsProvider =
    FutureProvider.autoDispose<List<Convo>>((ref) async {
  final allRooms = ref.watch(chatsProvider);
  if (!ref.watch(hasRoomFilters)) {
    throw 'No filters selected';
  }

  final foundRooms = List<Convo>.empty(growable: true);

  final search = ref.watch(roomListFilterProvider);
  for (final convo in allRooms) {
    if (await roomListFilterStateAppliesToRoom(search, ref, convo)) {
      foundRooms.add(convo);
    }
  }

  return foundRooms;
});

// for desktop only
final inSideBarProvider = StateProvider<bool>((ref) => false);
final hasExpandedPanel = StateProvider<bool>((ref) => false);

// get status of room encryption
final isRoomEncryptedProvider =
    FutureProvider.family<bool, String>((ref, roomId) async {
  final convo = await ref.watch(chatProvider(roomId).future);
  return await convo.isEncrypted();
});

typedef Mentions = List<Map<String, String>>;

final chatMentionsProvider =
    FutureProvider.autoDispose.family<Mentions, String>((ref, roomId) async {
  final activeMembers = await ref.read(membersIdsProvider(roomId).future);
  List<Map<String, String>> mentionRecords = [];
  for (final mId in activeMembers) {
    final data = await ref
        .watch(roomMemberProvider((roomId: roomId, userId: mId)).future);
    Map<String, String> record = {};
    final displayName = data.profile.displayName;
    record['id'] = mId;
    record['displayName'] = '$displayName';
    // all of our search terms:
    record['display'] = '$displayName $mId';
    mentionRecords.add(record);
  }
  return mentionRecords;
});
