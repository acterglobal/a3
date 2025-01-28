import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:acter_notifify/processing/parent_data.dart';

(String, String?) titleAndBodyForAttachment(NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final attachmentTitle = notification.title();

  final content =
      "$username added ${PushStyles.attachment.emoji} $attachmentTitle";

  final parent = notification.parent();
  if (parent != null) {
    final parentInfo = parentPart(parent);
    return (parentInfo, content);
  } else {
    return (content, null);
  }
}
