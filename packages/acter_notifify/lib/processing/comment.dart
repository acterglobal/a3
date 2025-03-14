import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:acter_notifify/processing/utils.dart';

(String, String?) titleAndBodyForComment(NotificationItem notification) {
  final emoji = PushStyles.comment.emoji;
  final title = notification.getUserCentricTitlePart(emoji, 'commented');

  //Generate comment body
  String? body;
  final comment = notification.body()?.body();
  final parentInfo = notification.parent()?.parentPart();

  if (parentInfo != null) {
    final content = comment != null ? ': $comment' : '';
    body = "On $parentInfo$content";
  } else {
    body = comment;
  }

  return (title, body);
}
