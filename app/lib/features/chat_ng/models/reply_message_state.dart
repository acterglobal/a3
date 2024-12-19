import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show RoomMessage;

// State to represent reply message status
sealed class ReplyMsgState {
  const ReplyMsgState();
}

class ReplyMsgLoading extends ReplyMsgState {
  const ReplyMsgLoading();
}

class ReplyMsgError extends ReplyMsgState {
  final String msgId;
  final Object? error;
  final StackTrace? stackTrace;

  const ReplyMsgError(this.msgId, this.error, this.stackTrace);
}

class ReplyMsgData extends ReplyMsgState {
  final RoomMessage message;
  const ReplyMsgData(this.message);
}
