import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/parent_data_process.dart';

(String, String?) titleAndBodyForObjectOtherChanges(
    NotificationItem notification) {
  //Generate body
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  String? body = 'by $username';

  //Generate title
  final parent = notification.parent();
  String title;
  if (parent != null) {
    final parentInfo = parentPart(parent);
    title = '$parentInfo updated';
  } else {
    title = '$username updated object';
    body = null;
  }

  return (title, body);
}
