import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/html_editor/models/mention_type.dart';
import 'package:acter/features/chat_ng/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat_ng/providers/notifiers/chat_room_messages_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::chat::message_provider');
const _supportedTypes = [
  'm.room.member',
  'm.room.message',
  'm.room.redaction',
  'm.room.encrypted',
];

typedef RoomMsgId = (String roomId, String uniqueId);
typedef MentionQuery = (String, MentionType);

final chatStateProvider = StateNotifierProvider.family<ChatRoomMessagesNotifier,
    ChatRoomState, String>(
  (ref, roomId) => ChatRoomMessagesNotifier(ref: ref, roomId: roomId),
);

final chatRoomMessageProvider =
    StateProvider.family<RoomMessage?, RoomMsgId>((ref, roomMsgId) {
  final (roomId, uniqueMsgId) = roomMsgId;
  final chatRoomState = ref.watch(chatStateProvider(roomId));
  return chatRoomState.message(uniqueMsgId);
});

final showHiddenMessages = StateProvider((ref) => false);

final animatedListChatMessagesProvider =
    StateProvider.family<GlobalKey<AnimatedListState>, String>(
  (ref, roomId) => ref.watch(chatStateProvider(roomId).notifier).animatedList,
);

final renderableChatMessagesProvider =
    StateProvider.autoDispose.family<List<String>, String>((ref, roomId) {
  final msgList =
      ref.watch(chatStateProvider(roomId).select((value) => value.messageList));
  if (ref.watch(showHiddenMessages)) {
    // do not apply filters
    return msgList;
  }
  // do apply some filters

  return msgList.where((id) {
    final msg = ref.watch(chatRoomMessageProvider((roomId, id)));
    if (msg == null) {
      _log.severe('Room Msg $roomId $id not found');
      return false;
    }
    return _supportedTypes.contains(msg.eventItem()?.eventType());
  }).toList();
});

// Provider to check if we should show avatar by comparing with the next message
final shouldShowAvatarProvider = Provider.family<bool, RoomMsgId>(
  (ref, roomMsgId) {
    final roomId = roomMsgId.$1;
    final eventId = roomMsgId.$2;
    final messages = ref.watch(renderableChatMessagesProvider(roomId));
    final currentIndex = messages.indexOf(eventId);

    // Always show avatar for the first message (last in the list)
    if (currentIndex == messages.length - 1) return true;

    // Get current and next message
    final currentMsg = ref.watch(chatRoomMessageProvider(roomMsgId));
    final nextMsg = ref.watch(
      chatRoomMessageProvider((roomId, messages[currentIndex + 1])),
    );

    if (currentMsg == null || nextMsg == null) return true;

    final currentSender = currentMsg.eventItem()?.sender();
    final nextSender = nextMsg.eventItem()?.sender();

    // Show avatar if next message is from a different sender
    return currentSender != nextSender;
  },
);

/// Provider to fetch user mentions
final userMentionSuggestionsProvider =
    StateProvider.family<Map<String, String>?, String>((ref, roomId) {
  final userId = ref.watch(myUserIdStrProvider);
  final members = ref.watch(membersIdsProvider(roomId)).valueOrNull;
  if (members == null) {
    return {};
  }
  return members.fold<Map<String, String>>({}, (map, uId) {
    if (uId != userId) {
      final displayName = ref.watch(
        memberDisplayNameProvider(
          (roomId: roomId, userId: uId),
        ),
      );
      map[uId] = displayName.valueOrNull ?? '';
    }
    return map;
  });
});

/// Provider to fetch room mentions
final roomMentionsSuggestionsProvider =
    StateProvider.family<Map<String, String>?, String>((ref, roomId) {
  final rooms = ref.watch(chatIdsProvider);
  return rooms.fold<Map<String, String>>({}, (map, roomId) {
    if (roomId == roomId) return map;

    final displayName = ref.watch(roomDisplayNameProvider(roomId));
    map[roomId] = displayName.valueOrNull ?? '';
    return map;
  });
});

/// High Level Provider to fetch user/room mentions
final mentionSuggestionsProvider =
    StateProvider.family<Map<String, String>?, (String, MentionType)>(
        (ref, params) {
  final (roomId, mentionType) = params;
  return switch (mentionType) {
    MentionType.user => ref.watch(userMentionSuggestionsProvider(roomId)),
    MentionType.room => ref.watch(roomMentionsSuggestionsProvider(roomId)),
  };
});
