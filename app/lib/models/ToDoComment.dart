import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show CommentDraft;

class ToDoComment {
  final String userId;
  final String? text;
  final CommentDraft replyBuilder;
  final DateTime time;

  const ToDoComment({
    required this.userId,
    required this.replyBuilder,
    required this.time,
    this.text,
  });
}
