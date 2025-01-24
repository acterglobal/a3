import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
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

(String, String?) titleAndBodyForEventRsvpYes(NotificationItem notification) {
  //Generate comment title
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  String title = "${PushStyles.rsvpYes.emoji} $username will join";

  //Generate comment body
  String? body;
  final parent = notification.parent();
  if (parent != null) {
    final parentInfo = parentPart(parent);
    body = parentInfo;
  }

  return (title, body);
}

(String, String?) titleAndBodyForEventRsvpMaybe(NotificationItem notification) {
  //Generate comment title
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  String title = "${PushStyles.rsvpMaybe.emoji} $username might join";

  //Generate comment body
  String? body;
  final parent = notification.parent();
  if (parent != null) {
    final parentInfo = parentPart(parent);
    body = parentInfo;
  }

  return (title, body);
}

(String, String?) titleAndBodyForEventRsvpNo(NotificationItem notification) {
  //Generate comment title
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  String title = "${PushStyles.rsvpNo.emoji} $username will not join";

  //Generate comment body
  String? body;
  final parent = notification.parent();
  if (parent != null) {
    final parentInfo = parentPart(parent);
    body = parentInfo;
  }

  return (title, body);
}
