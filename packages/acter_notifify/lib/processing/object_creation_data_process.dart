import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/parent_data_process.dart';

(String, String?) titleAndBodyForObjectCreation(NotificationItem notification) {
  //Generate body
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final spaceName = notification.title();

  String? body = 'by $username in "$spaceName"';

  //Generate title
  final parent = notification.parent();
  String title;
  if (parent != null) {
    final parentInfo = parentPart(parent);
    title = '$parentInfo created';
  } else {
    title = '$username created object in "$spaceName"';
    body = null;
  }

  return (title, body);
}
