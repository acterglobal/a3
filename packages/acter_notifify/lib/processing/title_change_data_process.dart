
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/parent_data_process.dart';

(String, String?) titleAndBodyForObjectTitleChange(
    NotificationItem notification) {
  //Generate body
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final newTitle = notification.title();

  String? body = 'by $username to "$newTitle"';

  //Generate title
  final parent = notification.parent();
  String title;
  if (parent != null) {
    final parentInfo = parentPart(parent);
    title = '$parentInfo renamed';
  } else {
    title = '$username renamed title to "$newTitle"';
    body = null;
  }

  return (title, body);
}