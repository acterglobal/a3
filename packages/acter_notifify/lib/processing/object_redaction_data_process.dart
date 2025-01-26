import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/parent_data_process.dart';

(String, String?) titleAndBodyForObjectRedaction(NotificationItem notification) {
  //Generate body
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final spaceName = notification.title();

  String? body = 'by $username from "$spaceName"';

  //Generate title
  final parent = notification.parent();
  String title;
  if (parent != null) {
    final parentInfo = parentPart(parent);
    title = '$parentInfo removed';
  } else {
    title = '$username removed object from "$spaceName"';
    body = null;
  }

  return (title, body);
}
