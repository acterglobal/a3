import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/parent_data_process.dart';

(String, String?) titleAndBodyForTaskAdd(NotificationItem notification) {
  //Generate title
  final referencesObject = notification.title();
  String title = '$referencesObject added';

  //Generate body
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  String? body;

  final parent = notification.parent();
  if (parent != null) {
    final parentInfo = parentPart(parent);
    body = 'by $username in "$parentInfo"';
  } else {
    title = '$username added Task';
  }

  return (title, body);
}
