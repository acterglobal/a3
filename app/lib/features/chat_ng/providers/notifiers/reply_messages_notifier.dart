import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/models/reply_message_state.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::reply_notifier');

class ReplyMessageNotifier
    extends AutoDisposeFamilyAsyncNotifier<ReplyMsgState, RoomMsgId> {
  Future<void> retryLoad() async {
    state = await AsyncValue.guard(() => build(arg));
  }

  @override
  Future<ReplyMsgState> build(RoomMsgId arg) async {
    try {
      final timeline =
          await ref.watch(timelineStreamProvider(arg.roomId).future);
      final roomMsg = await timeline.getMessage(arg.uniqueId);
      return ReplyMsgData(roomMsg);
    } catch (e, s) {
      _log.severe(
        'Failed to load reference ${arg.uniqueId})',
        e,
        s,
      );
      return ReplyMsgError(arg.uniqueId, e, s);
    }
  }
}
