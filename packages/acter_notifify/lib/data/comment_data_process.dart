import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/data/data_contants.dart';
import 'package:acter_notifify/data/parent_data_process.dart';

(String, String?) titleAndBodyForComment(NotificationItem notification) {
  final parent = notification.parent();
  String title = "${PushStyles.comment.emoji} Comment";
  if (parent != null) {
    final parentInfo = parentPart(parent);
    title = "$title on $parentInfo";
  }

  final comment = notification.body()?.body();
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  return (title, "$username: $comment");
}
