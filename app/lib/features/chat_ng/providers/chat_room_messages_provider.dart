import 'package:acter/features/chat_ng/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat_ng/providers/notifiers/chat_room_messages_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
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
    final type = msg.eventItem()?.eventType();
    print(type);
    return _supportedTypes.contains(type);
  }).toList();
});
