import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:acter/features/chat/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat/models/media_chat_state/media_chat_state.dart';
import 'package:acter/features/chat/providers/notifiers/chat_input_notifier.dart';
import 'package:acter/features/chat/providers/notifiers/chat_room_notifier.dart';
import 'package:acter/features/chat/providers/notifiers/media_chat_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatInputProvider =
    StateNotifierProvider.family<ChatInputNotifier, ChatInputState, String>(
  (ref, roomId) => ChatInputNotifier(),
);

final chatInputFocusProvider = StateProvider<FocusNode>((ref) => FocusNode());
final chatStateProvider =
    StateNotifierProvider.family<ChatRoomNotifier, ChatRoomState, Convo>(
  (ref, convo) => ChatRoomNotifier(ref: ref, convo: convo),
);

final mediaChatStateProvider =
    StateNotifierProvider.family<MediaChatNotifier, MediaChatState, String>(
  (ref, messageId) => MediaChatNotifier(ref: ref, messageId: messageId),
);

final chatSearchValueProvider =
    StateProvider.autoDispose<String?>((ref) => null);

final searchedChatsProvider =
    FutureProvider.autoDispose<List<Convo>>((ref) async {
  final allRooms = ref.watch(chatsProvider);
  final searchValue = ref.watch(chatSearchValueProvider);
  if (searchValue == null || searchValue.isEmpty) {
    return allRooms;
  }

  final searchTerm = searchValue.toLowerCase();

  final foundRooms = List<Convo>.empty(growable: true);

  for (final convo in allRooms) {
    final profile = await ref.watch(chatProfileDataProvider(convo).future);
    final name = profile.displayName ?? convo.getRoomIdStr();
    if (name.toLowerCase().contains(searchTerm)) {
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
