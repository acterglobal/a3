import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/models/replied_to_msg_state.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::replied_to_notifier');

class RepliedToMessageNotifier
    extends AutoDisposeFamilyAsyncNotifier<RepliedToMsgState, RoomMsgId> {
  Future<void> retryLoad() async {
    state = await AsyncValue.guard(() => build(arg));
  }

  @override
  Future<RepliedToMsgState> build(RoomMsgId arg) async {
    try {
      final timeline = await ref.watch(
        timelineStreamProvider(arg.roomId).future,
      );
      final roomMsg = await timeline.getMessage(arg.uniqueId);
      final repliedToItem = roomMsg.eventItem().expect(
        'msg should have event item',
      );
      return RepliedToMsgData(repliedToItem);
    } catch (e, s) {
      _log.severe('Failed to load reference ${arg.uniqueId})', e, s);
      return RepliedToMsgError(arg.uniqueId, e, s);
    }
  }
}
