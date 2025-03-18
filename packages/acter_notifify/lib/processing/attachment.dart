import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:acter_notifify/processing/utils.dart';

(String, String?) titleAndBodyForAttachment(NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final attachmentTitle = notification.title();

  final content =
      "$username added ${PushStyles.attachment.emoji} $attachmentTitle";

  final parentInfo = notification.parent()?.parentPart();
  if (parentInfo != null) {
    return (parentInfo, content);
  } else {
    return (content, null);
  }
}
