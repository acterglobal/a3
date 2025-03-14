import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/utils.dart';

(String, String?) titleAndBodyForTaskAdd(NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final referencesObject = notification.title();

  final parentInfo = notification.parent()?.parentPart();
  if (parentInfo != null) {
    final title = '$referencesObject added';
    final body = 'by $username in "$parentInfo"';
    return (title, body);
  } else {
    final title = '$username added "$referencesObject"';
    return (title, null);
  }
}
