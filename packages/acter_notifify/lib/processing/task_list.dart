import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/utils.dart';

(String, String?) titleAndBodyForTaskAdd(NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final referencesObject = notification.title();

  final parent = notification.parent();
  if (parent != null) {
    final parentInfo = parentPart(parent);
    final title = '$referencesObject added';
    final body = 'by $username in "$parentInfo"';
    return (title, body);
  } else {
    final title = '$username added "$referencesObject"';
    return (title, null);
  }
}
