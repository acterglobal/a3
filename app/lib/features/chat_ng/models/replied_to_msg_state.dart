import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomEventItem;

// State to represent reply message status
sealed class RepliedToMsgState {
  const RepliedToMsgState();
}

class RepliedToMsgLoading extends RepliedToMsgState {
  const RepliedToMsgLoading();
}

class RepliedToMsgError extends RepliedToMsgState {
  final String msgId;
  final Object? error;
  final StackTrace? stackTrace;

  const RepliedToMsgError(this.msgId, this.error, this.stackTrace);
}

class RepliedToMsgData extends RepliedToMsgState {
  final RoomEventItem repliedToItem;
  const RepliedToMsgData(this.repliedToItem);
}
