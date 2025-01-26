import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/parent_data_process.dart';

(String, String?) titleAndBodyForReferences(NotificationItem notification) {
  //Generate body
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final referencesObject = notification.title();

  String? body =
      "$username linked $referencesObject";

  //Generate title
  final parent = notification.parent();
  String title;
  if (parent != null) {
    final parentInfo = parentPart(parent);
    title = parentInfo;
  } else {
    title = body;
    body = null;
  }

  return (title, body);
}
