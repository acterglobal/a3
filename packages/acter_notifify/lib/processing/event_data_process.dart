import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/parent_data_process.dart';

(String, String?) titleAndBodyForEventDateChange(
    NotificationItem notification) {
  //Generate attachment body
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final newEventDate = notification.title();

  String? body = 'by $username to "$newEventDate"';

  //Generate attachment title
  final parent = notification.parent();
  String title;
  if (parent != null) {
    final parentInfo = parentPart(parent);
    title = '$parentInfo rescheduled';
  } else {
    title = '$username rescheduled event to "$newEventDate"';
    body = null;
  }

  return (title, body);
}
