import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/html_editor/components/mention_block.dart';
import 'package:acter/features/chat_ng/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat_ng/providers/notifiers/chat_room_messages_notifier.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::chat::message_provider');

typedef RoomMsgId = (String roomId, String uniqueId);

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

const _supportedTypes = ['m.room.message'];

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

final mentionSuggestionsProvider =
    Provider.family<Map<String, String>, (String, MentionType)>((ref, params) {
  final roomId = params.$1;
  final mentionType = params.$2;
  final client = ref.watch(alwaysClientProvider);
  final userId = client.userId().toString();

  switch (mentionType) {
    case MentionType.user:
      final members = ref.watch(membersIdsProvider(roomId)).valueOrNull;
      if (members != null) {
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
      }

    case MentionType.room:
      final rooms = ref.watch(chatIdsProvider);
      return rooms.fold<Map<String, String>>({}, (map, roomId) {
        final displayName = ref.watch(roomDisplayNameProvider(roomId));
        map[roomId] = displayName.valueOrNull ?? '';
        return map;
      });
  }
  return {};
});
