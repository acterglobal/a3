import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/models/reply_message_state.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::reply_notifier');

class ReplyMessageNotifier
    extends AutoDisposeFamilyAsyncNotifier<ReplyMsgState, ReplyMsgInfo> {
  Future<void> retryLoad() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(arg));
  }

  @override
  Future<ReplyMsgState> build(ReplyMsgInfo arg) async {
    // Watch messages to react to changes
    final messages = ref.watch(
      chatStateProvider(arg.roomId).select((value) => value.messageList),
    );

    // First try to find message in current state
    final messageId = messages.firstWhere(
      (eventId) => eventId == arg.originalId,
      orElse: () => '',
    );

    if (messageId.isNotEmpty) {
      RoomMsgId msgInfo = (arg.roomId, arg.originalId);
      final message = ref.watch(chatRoomMessageProvider(msgInfo));
      if (message == null) {
        _log.severe(
          'Failed to load message ${arg.originalId})',
          null,
          null,
        );
        return ReplyMsgError(arg.originalId, arg.messageId, null, null);
      }
      return ReplyMsgData(message);
    }

    // If not in list, try to fetch from server
    try {
      final convo = await ref.watch(chatProvider(arg.roomId).future);
      if (convo == null) {
        _log.severe(
          'Failed to load room ${arg.roomId})',
          null,
          null,
        );
        return ReplyMsgError(arg.originalId, arg.messageId, null, null);
      }
      final timeline = convo.timelineStream();
      final roomMsg = await timeline.getMessage(arg.originalId);
      return ReplyMsgData(roomMsg);
    } catch (e, s) {
      _log.severe(
        'Failed to load reference ${arg.messageId} (from ${arg.originalId})',
        e,
        s,
      );
      return ReplyMsgError(arg.originalId, arg.messageId, e, s);
    }
  }
}
